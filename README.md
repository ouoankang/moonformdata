# MoonFormData

MoonFormData 是一个 MoonBit 原生的 `multipart/form-data` 表单解析与生成库，面向文件上传、Webhook、API 测试、HTTP 客户端、轻量网关和 Web 框架集成等场景。

项目定位是基础生态库：不实现 HTTP server，也不绑定某个 Web 框架，而是提供可被任意 MoonBit HTTP 栈复用的 multipart 表单处理能力。

## 功能

- 解析 `Content-Type: multipart/form-data; boundary=...`
- 解析 `Content-Disposition`、`name`、`filename`、`filename*` 和 part headers
- 解析 multipart body 为有序 `FormPart`，保留重复字段和同名多文件
- 支持普通字段、重复字段、多文件、空文件和自定义 header
- 生成 multipart body，方便 HTTP 客户端和 API 测试使用
- 提供表单构建器、请求封装、摘要查询、验证策略和错误报告
- 提供安全文件名处理，降低路径穿越、控制字符和危险扩展名风险
- 提供回归 fixture 和黑盒测试，覆盖常见成功路径与错误边界

## 安装

发布到 mooncakes.io 后：

```bash
moon add moonbit-community/moonformdata
```

在 `moon.pkg` 中引入：

```moonbit
import {
  "moonbit-community/moonformdata" @moonformdata,
}
```

## 快速开始

```moonbit
let body =
  "--demo\r\n" +
  "Content-Disposition: form-data; name=\"title\"\r\n" +
  "\r\n" +
  "MoonFormData demo\r\n" +
  "--demo\r\n" +
  "Content-Disposition: form-data; name=\"upload\"; filename=\"..\\\\report.txt\"\r\n" +
  "Content-Type: text/plain\r\n" +
  "\r\n" +
  "hello from MoonBit\r\n" +
  "--demo--\r\n"

match @moonformdata.parse_multipart(body, "demo") {
  Ok(form) => {
    println(form.field_value("title").unwrap_or("<missing>"))
    let files = form.files("upload")
    println(files[0].filename.unwrap_or("<none>"))
  }
  Err(err) => println(err.message())
}
```

运行示例：

```bash
moon run cmd/main
```

## 构建请求

```moonbit
let request = @moonformdata.build_upload_request(
  [("title", "demo")],
  [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
  boundary="demo-boundary",
)
```

`build_upload_request` 会返回可直接用于 HTTP 客户端的 `content_type` 和 `body`。

## 验证上传

```moonbit
let policy = @moonformdata.validation_policy_require_file(
  @moonformdata.default_validation_policy(),
  "upload",
)
```

`ValidationPolicy` 可配置必填字段、必填文件、允许的文件类型、文本大小、文件大小、文件名长度、是否允许空文件和是否允许重复字段。

## 主要 API

- `boundary_from_content_type(header) -> Result[String, MultipartError]`
- `parse_multipart(body, boundary) -> Result[MultipartForm, MultipartError]`
- `parse_multipart_request(content_type, body) -> Result[MultipartForm, MultipartError]`
- `parse_multipart_with_options(body, boundary, options) -> Result[MultipartForm, MultipartError]`
- `encode_multipart(parts, boundary?) -> Result[EncodedForm, MultipartError]`
- `build_request_from_fields(fields, boundary?) -> Result[MultipartRequest, MultipartError]`
- `build_upload_request(fields, files, boundary?) -> Result[MultipartRequest, MultipartError]`
- `text_part(name, value) -> FormPart`
- `file_part(name, filename, body, content_type?) -> FormPart`
- `safe_filename(filename) -> String`
- `sanitize_filename_with_policy(filename, policy) -> String`
- `validate_form(form, policy) -> ValidationReport`

## 查询能力

`MultipartForm` 提供常用查询方法：

- `field_value(name)`
- `field_values(name)`
- `files(name)`
- `field_names()`
- `file_field_names()`
- `summary()`
- `debug_lines()`
- `require_field(name)`
- `require_file(name)`

## 错误处理

解析和生成 API 使用 `Result[T, MultipartError]` 返回错误，覆盖：

- `MissingBoundary`
- `InvalidBoundary`
- `InvalidHeader`
- `InvalidContentType`
- `InvalidContentDisposition`
- `MalformedBody`
- `LimitExceeded`

可用 `err.message()` 生成适合日志、CLI 和 HTTP 400 响应的错误说明。

## 测试与质量

本仓库提供可运行示例、黑盒测试、边界测试和回归语料。

```bash
moon check
moon build
moon test
moon run cmd/main
moon package --list
```

当前本地验证结果：

- 有效 MoonBit LOC：4012
- 测试数量：46
- `moon check`：通过
- `moon test`：通过
- `moon run cmd/main`：通过
- `moon package --list`：通过

CI 会在 push 和 pull request 时运行检查、构建、测试、示例和包列表流程。

## 项目边界

- v1 是内存版解析器，适合小到中等大小的表单请求体。
- v1 不实现完整 HTTP server。
- v1 不做复杂嵌套 multipart 的递归解析。
- v1 不承诺浏览器 FormData 全量兼容，优先覆盖常见工程场景。

## 开源合规

项目采用 Apache-2.0 许可证。

项目为原创 MoonBit 实现，不直接复制或移植其他语言项目代码。行为设计参考公开标准：

- RFC 7578: Returning Values from Forms: multipart/form-data
- RFC 2046: Multipurpose Internet Mail Extensions, multipart media type
- RFC 2183: Content-Disposition
- RFC 5987: Character Set and Language Encoding for HTTP Header Field Parameters
