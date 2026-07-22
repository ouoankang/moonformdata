# MoonFormData

MoonFormData 是一个 MoonBit 原生 `multipart/form-data` 表单解析与生成库，面向文件上传、Webhook、API 测试、HTTP 客户端、轻量网关和 Web 框架集成。

## 项目目标

MoonFormData 聚焦可复用的 multipart 基础能力：解析请求体、生成请求体、查询字段和文件、处理安全文件名、执行上传校验，并提供可复现示例和测试。项目不绑定具体 HTTP server 或 Web 框架，适合作为 MoonBit HTTP 工具链和应用库的基础组件。

## 当前状态

| 项目 | 状态 |
| --- | --- |
| 包名 | `moonbit-community/moonformdata` |
| 版本 | `0.1.0` |
| MoonBit 实现 | 核心功能均由 MoonBit 实现 |
| 代码规模 | 有效 MoonBit 代码超过 4000 行 |
| 测试 | 74 个测试，覆盖核心路径、错误路径、边界情况和白盒 helper |
| 示例 | `cmd/main` 和 `examples/basic` 均可运行 |
| CI | GitHub Actions 覆盖检查、构建、测试、JS 目标、示例和包清单检查 |
| 许可证 | Apache-2.0 |

## 安装

Mooncakes 包名：

```bash
moon add moonbit-community/moonformdata
```

在 `moon.pkg` 中引用：

```moonbit
import {
  "moonbit-community/moonformdata" @moonformdata,
}
```

## 最小示例

```moonbit
let body =
  "--demo\r\n" +
  "Content-Disposition: form-data; name=\"title\"\r\n" +
  "\r\n" +
  "MoonFormData\r\n" +
  "--demo\r\n" +
  "Content-Disposition: form-data; name=\"upload\"; filename=\"..\\\\report.txt\"\r\n" +
  "Content-Type: text/plain\r\n" +
  "\r\n" +
  "hello from MoonBit\r\n" +
  "--demo--\r\n"

match @moonformdata.parse_multipart(body, "demo") {
  Ok(form) => {
    println(form.require_field("title").unwrap())
    println(form.require_file("upload").unwrap().filename_or("<none>"))
  }
  Err(err) => println(err.message())
}
```

## 运行示例

```bash
moon run cmd/main
moon run examples/basic
```

`examples/basic` 会演示生成上传请求、解析请求、读取字段和文件、执行 schema 校验、输出分析摘要。

## 主要功能

- 解析 `Content-Type: multipart/form-data; boundary=...`
- 解析 `Content-Disposition`、`name`、`filename`、`filename*` 和 part headers
- 解析普通字段、重复字段、同名多文件、空文件和自定义 header
- 生成 HTTP-ready multipart body 和 `Content-Type`
- 提供 `MultipartForm` 查询 API
- 提供安全文件名处理，降低路径穿越、控制字符和危险扩展名风险
- 提供通用 `ValidationPolicy` 和声明式 `FormSchema`
- 提供 `FormAnalysis`，用于 CLI、日志、Webhook 调试和验收报告
- 提供回归 fixture、黑盒测试、白盒测试和 JS 目标测试

## API 概览

| 分类 | API |
| --- | --- |
| 解析 | `boundary_from_content_type`, `parse_multipart`, `parse_multipart_with_options`, `parse_multipart_request` |
| 生成 | `encode_multipart`, `encode_fields`, `encode_files`, `encode_fields_and_files`, `build_upload_request` |
| Part 构造 | `text_part`, `file_part`, `empty_file_part`, `part_add_header`, `part_replace_header` |
| 查询 | `field_value`, `field_values`, `files`, `require_field`, `require_file`, `summary`, `debug_lines` |
| 安全 | `safe_filename`, `sanitize_filename_with_policy`, `strict_filename_policy`, `image_filename_policy` |
| 校验 | `validate_form`, `default_validation_policy`, `strict_validation_policy`, `validate_form_schema`, `field_rule`, `file_rule` |
| 分析 | `analyze_form`, `analyze_request`, `request_analysis_lines`, `form_name_counts`, `form_content_type_counts` |

完整 API 见 [docs/API.md](docs/API.md)。

## 支持范围

- 内存版 multipart body 解析
- CRLF 和 LF-only 换行
- 普通文本字段
- 重复字段
- 文件字段
- 同名多文件
- 空文件
- 自定义 part header
- `filename` 和常见 `filename*` 百分号编码
- 可配置解析限制
- 可配置上传校验
- 可运行示例和回归测试

## 暂不支持范围

- 完整 HTTP server
- 流式大文件解析
- 复杂嵌套 multipart 递归解析
- 浏览器 `FormData` 全量兼容矩阵
- 文件落盘、对象存储或云上传适配器

## 错误处理

所有可能失败的 API 返回 `Result[..., MultipartError]`。错误类型包括：

| 错误 | 含义 |
| --- | --- |
| `MissingBoundary` | 缺少 boundary |
| `InvalidBoundary` | boundary 为空、过长或包含非法字符 |
| `InvalidHeader` | part header 格式非法 |
| `InvalidContentType` | Content-Type 不是合法 multipart/form-data |
| `InvalidContentDisposition` | Content-Disposition 缺失或非法 |
| `MalformedBody` | 请求体边界、分隔符或结束边界错误 |
| `LimitExceeded` | 超过解析限制 |

可使用 `err.message()` 生成日志、CLI 输出或 HTTP 400 响应文本。

## 测试和验收命令

```bash
moon check
moon build
moon test
moon check --target js
moon build --target js
moon test --target js
moon run cmd/main
moon run examples/basic
moon package --list
moon publish --dry-run
```

`moon publish --dry-run` 需要先完成 `moon login`，用于正式发布前的 Mooncakes 打包与发布流程检查。

详细测试说明见 [docs/TESTING.md](docs/TESTING.md)。

## 文档

- [API](docs/API.md)
- [设计说明](docs/DESIGN.md)
- [测试说明](docs/TESTING.md)
- [提交说明](docs/SUBMISSION.md)

## 开源许可证

本项目采用 Apache-2.0 许可证。项目为原创 MoonBit 实现，不直接复制或移植其他语言项目代码。行为设计参考公开的 multipart/form-data、MIME multipart、Content-Disposition 和 HTTP header 参数相关规范。
