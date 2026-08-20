# MoonFormData

MoonFormData 是一个 MoonBit 原生 `multipart/form-data` 表单解析与生成库，重点提供上传契约、声明式 Schema、安全校验和可复现诊断报告，面向文件上传、Webhook、API 测试、轻量网关和 Web 框架集成。

## 项目目标

MoonFormData 把 multipart 解析、生成、字段查询、文件名治理、Schema 校验和风险分析组合成可执行的上传契约。项目不绑定具体 HTTP server 或 Web 框架，适合作为 MoonBit API 端点、Webhook 和自动化测试的请求验收层。

## 当前状态

| 项目 | 状态 |
| --- | --- |
| 包名 | `ouoankang/moonformdata` |
| 版本 | `0.1.0` |
| MoonBit 实现 | 核心功能均由 MoonBit 实现 |
| 代码规模 | 有效 MoonBit 代码超过 6000 行 |
| 测试 | 81 个测试，覆盖核心路径、错误路径、边界情况、上传契约和白盒 helper |
| 示例 | `cmd/main` 和 `examples/basic` 均可运行 |
| CI | GitHub Actions 覆盖检查、构建、测试、JS 目标、示例和包清单检查 |
| 许可证 | Apache-2.0 |

## 生态定位与差异

Mooncakes 中已有 `GCodinggo/moon-multipart` 和 `Songyz002/moon-multipart`，其公开包元数据与 README 聚焦 RFC 7578、字节数据和流式 parser/writer。MoonFormData 不与它们竞争大文件流式处理，而是提供应用层的 multipart 上传契约与质量诊断。

| 维度 | MoonFormData | 现有 `moon-multipart` 公开定位 |
| --- | --- | --- |
| 核心输入 | 内存请求体与端点 Schema | 字节流与 multipart 分块 |
| 核心交付 | `UploadContract`、验收决策、稳定诊断报告 | 流式解析事件和 writer |
| 应用校验 | 命名字段/文件规则、未知项拒绝、风险阈值 | 传输层限制和 RFC 校验 |
| 回归能力 | 84 组语料、默认/JS 双目标、可复现报告 | 流式边界与安全用例 |

两类项目面向不同集成层。MoonFormData 不依赖、移植或复制这些项目的代码，详细说明见 [生态差异](docs/ECOSYSTEM.md)。

## 安装

Mooncakes 包名：

```bash
moon add ouoankang/moonformdata
```

在 `moon.pkg` 中引用：

```moonbit
import {
  "ouoankang/moonformdata" @moonformdata,
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

## 上传契约示例

```moonbit
let schema = @moonformdata.strict_form_schema()
  .add_field_rule(@moonformdata.required_field_rule("title"))
  .add_file_rule(
    @moonformdata.required_file_rule("upload")
    .with_max_files(1)
    .allow_content_type("text/plain")
    .allow_extension("txt"),
  )
let contract = @moonformdata.upload_contract(schema)
  .with_max_risk(@moonformdata.LowRisk)

match @moonformdata.inspect_upload_request(request, contract) {
  Ok(result) => println(result.decision_line())
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
- 提供 `UploadContract` 与 `UploadInspection`，统一执行解析限制、Schema、风险阈值和验收决策
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
| 上传契约 | `upload_contract`, `inspect_upload`, `inspect_upload_request`, `UploadInspection::decision_line` |

完整 API 见 [docs/API.md](docs/API.md)。

## 支持范围

- 以 MoonBit `String` 为载体的内存版 multipart body 解析
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
- 可组合解析限制、Schema 和风险阈值的端点上传契约
- 可运行示例和回归测试

## 暂不支持范围

- 完整 HTTP server
- 流式大文件解析
- 任意二进制字节流 API；大文件或原始 `Bytes` 场景应使用流式 multipart 库
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
moon fmt --check
moon check --deny-warn
moon build
moon test --deny-warn
moon check --target js
moon build --target js
moon test --target js
moon run cmd/main
moon run examples/basic
moon info
moon package --list
moon publish --dry-run
```

`moon publish --dry-run` 需要先完成 `moon login`，用于正式发布前的 Mooncakes 打包与发布流程检查。

详细测试说明见 [docs/TESTING.md](docs/TESTING.md)。

## 文档

- [API](docs/API.md)
- [设计说明](docs/DESIGN.md)
- [测试说明](docs/TESTING.md)
- [生态定位与差异](docs/ECOSYSTEM.md)
- [提交说明](docs/SUBMISSION.md)
- [作者与提交身份说明](AUTHORS.md)

## 开源许可证

本项目采用 Apache-2.0 许可证。项目为原创 MoonBit 实现，不直接复制或移植其他语言项目代码。行为设计参考公开的 multipart/form-data、MIME multipart、Content-Disposition 和 HTTP header 参数相关规范。
