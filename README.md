# MoonFormData

MoonFormData 是一个 MoonBit 原生 `multipart/form-data` 表单解析、生成与上传契约治理工具包。它面向文件上传端点、Webhook、轻量网关、HTTP 客户端和 API 回归测试，把 multipart 请求转换为可校验、可演进、可追踪的应用层契约。

## 生态定位

Mooncakes 已有 `GCodinggo/moon-multipart` 和 `Songyz002/moon-multipart`，公开定位主要是 RFC 7578 字节流 parser/writer 与大文件传输。MoonFormData 不重复流式传输层，而是覆盖完整请求体进入应用后的治理流程。

| 能力层 | MoonFormData | 现有 `moon-multipart` 公开定位 |
| --- | --- | --- |
| 数据处理 | 有界内存请求体、结构化字段与文件模型 | `Bytes`、分块事件、流式 writer |
| 端点规则 | 命名 Schema、未知项策略、风险阈值、接受/拒绝决策 | RFC framing 与传输限制 |
| API 演进 | 契约版本差异、破坏性变更分级 | 未作为主要能力公开 |
| 回归治理 | 批量一致性套件、多端点目录、可保存基线、Markdown 报告 | 未作为主要能力公开 |

项目为独立原创实现，不依赖、移植或复制上述包。完整对比见 [生态定位与差异](docs/ECOSYSTEM.md)。

## 质量状态

| 项目 | 状态 |
| --- | --- |
| 包名与版本 | `ouoankang/moonformdata` `0.1.0` |
| 主要语言 | 核心功能全部使用 MoonBit 实现 |
| 代码规模 | 9,000 行以上有效 MoonBit 代码 |
| 自动测试 | 112 个，覆盖解析、错误、边界、安全、契约和治理流程 |
| 回归语料 | 84 组项目自有合成 multipart fixture |
| 示例 | `cmd/main`、`examples/basic`、`examples/governance` |
| CI | 格式、零警告检查、构建、测试、JS 目标、接口漂移和示例 |
| 许可证 | Apache-2.0 |

## 安装

```bash
moon add ouoankang/moonformdata
```

```moonbit
import {
  "ouoankang/moonformdata" @moonformdata,
}
```

## 解析示例

```moonbit
let body =
  "--demo\r\n" +
  "Content-Disposition: form-data; name=\"title\"\r\n" +
  "\r\n" +
  "MoonFormData\r\n" +
  "--demo--\r\n"

match @moonformdata.parse_multipart(body, "demo") {
  Ok(form) => println(form.require_field("title").unwrap())
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

## 契约治理示例

```moonbit
let diff = @moonformdata.compare_upload_contracts(v1_contract, v2_contract)
println(diff.summary())

let suite = @moonformdata.run_conformance_suite("avatar-v2", v2_contract, cases)
let baseline = @moonformdata.conformance_baseline(suite)
println(baseline.to_text())
```

完整示例同时演示契约差异、批量用例、多端点目录和基线比较：

```bash
moon run cmd/main
moon run examples/basic
moon run examples/governance
```

## 主要功能

- 解析 `Content-Type` boundary、`Content-Disposition`、part headers、`filename` 与 `filename*`
- 支持普通字段、重复字段、同名多文件、空文件、自定义 header、CRLF 与 LF-only 请求体
- 生成 HTTP-ready multipart body，并提供字段、文件和 Builder API
- 安全处理路径分隔符、盘符、控制字符、危险扩展名和超长文件名
- 使用 `ValidationPolicy` 与 `FormSchema` 校验必填项、数量、大小、类型、扩展名和未知项
- 使用 `UploadContract` 组合解析限制、Schema、风险阈值和端点决策
- 比较新旧契约，识别新增必填项、收紧限额、白名单缩小等破坏性变更
- 运行接受、拒绝、解析失败、错误码和风险等级一致性用例
- 按 HTTP 方法和路径管理多端点契约并生成一致性矩阵
- 序列化回归基线，检测用例删除、结果变化、失败回归和错误码漂移
- 输出稳定文本和 Markdown 报告，适合 CI、评审、Webhook 调试与 API 升级

## API 概览

| 分类 | 主要 API |
| --- | --- |
| 解析 | `boundary_from_content_type`, `parse_multipart`, `parse_multipart_with_options`, `parse_multipart_request` |
| 生成 | `encode_multipart`, `encode_fields_and_files`, `build_upload_request` |
| 查询 | `field_value`, `field_values`, `files`, `require_field`, `require_file`, `summary` |
| 安全 | `safe_filename`, `sanitize_filename_with_policy`, `strict_filename_policy` |
| 校验 | `validate_form`, `validate_form_schema`, `field_rule`, `file_rule` |
| 分析 | `analyze_form`, `FormAnalysis::to_lines`, `form_content_type_counts` |
| 上传契约 | `upload_contract`, `inspect_upload`, `inspect_upload_request`, `UploadInspection::decision_line` |
| 契约演进 | `compare_upload_contracts`, `ContractDiff::has_breaking_changes`, `ContractDiff::to_markdown` |
| 一致性套件 | `upload_conformance_case`, `run_conformance_suite`, `ConformanceSuiteResult::to_markdown` |
| 多端点目录 | `upload_endpoint`, `upload_contract_catalog`, `inspect_route`, `run_catalog_conformance` |
| 回归基线 | `conformance_baseline`, `parse_conformance_baseline`, `compare_conformance_baseline` |

完整接口见 [API 文档](docs/API.md)。

## 支持边界

支持：

- 以 MoonBit `String` 为载体的有界内存请求体
- 平面 multipart 表单、文本字段与文件字段
- 默认目标与 JS 目标
- 应用层 Schema、风险分析、契约演进和回归治理

不支持：

- 完整 HTTP server
- 任意二进制 `Bytes` 的流式大文件传输
- 复杂嵌套 multipart 递归解析
- 文件落盘、对象存储和云上传适配器
- 浏览器 `FormData` 全量兼容矩阵

需要分块读取或大文件直传时，应选用流式 multipart 包；需要端点级验收、API 兼容性和稳定诊断时，可直接使用 MoonFormData，或把它放在 HTTP 适配层之后。

## 错误模型

所有可能失败的解析 API 返回 `Result[..., MultipartError]`，可区分缺少 boundary、非法 header、非法 Content-Type、非法 Content-Disposition、损坏 body 和超过限制。目录路由与基线格式另有结构化错误类型，便于生成 HTTP 响应、日志或 CI 失败信息。

## 开发质量

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
moon run examples/governance
moon info
moon package --list
```

## 文档

- [API](docs/API.md)
- [设计说明](docs/DESIGN.md)
- [测试说明](docs/TESTING.md)
- [生态定位与差异](docs/ECOSYSTEM.md)
- [项目完成证据](docs/SUBMISSION.md)
- [作者与提交身份](AUTHORS.md)

## 开源合规

MoonFormData 采用 Apache-2.0 许可证。实现仅以 RFC 7578、RFC 2046、RFC 8187 等公开规范作为格式与行为依据；代码、示例、fixture 与测试均为项目原创或项目自有合成内容，不包含来源不明、私有或闭源代码。
