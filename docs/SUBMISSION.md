# MoonFormData 项目完成证据

| 项目 | 内容 |
| --- | --- |
| 正式名称 | MoonFormData：MoonBit 原生 multipart/form-data 表单解析与生成库 |
| GitHub | `https://github.com/ouoankang/moonformdata` |
| Mooncakes | `ouoankang/moonformdata` `0.1.0` |
| 项目性质 | 原创 MoonBit 开源项目 |
| 许可证 | Apache-2.0 |
| 主要语言 | MoonBit |
| 代码规模 | 9,000 行以上 MoonBit 代码 |
| 自动测试 | 112 个 |

## 完整功能

MoonFormData 已实现有界内存版 multipart parser/encoder、字段与文件查询、文件名安全处理、通用校验策略、命名 Schema、风险分析和上传接受/拒绝决策。在此基础上，项目已形成完整的上传契约治理工具链：

- 契约版本兼容性检查与破坏性变更分级；
- 接受、拒绝、解析失败、错误码和风险等级一致性套件；
- 按 HTTP 方法与路径组织的多端点版本化契约目录；
- 可序列化、可解析、适合 Git diff 的行为回归基线；
- 稳定文本、Markdown 报告和三个可运行示例。

## 生态差异

Mooncakes 中 `GCodinggo/moon-multipart` 与 `Songyz002/moon-multipart` 的公开定位侧重 RFC 7578 字节流 parser/writer 和大文件传输。MoonFormData 的核心价值位于应用层：命名 Schema、风险策略、端点决策、API 版本差异、批量一致性、多端点目录和回归基线。项目不依赖、移植或复制上述包，详细证据见 `docs/ECOSYSTEM.md`。

## 工程证据

| 证据 | 位置 |
| --- | --- |
| parser、encoder 与错误模型 | `moonformdata.mbt` |
| Schema、分析与上传契约 | `schema.mbt`、`analysis.mbt`、`contract.mbt` |
| 契约演进、一致性、目录与基线 | `evolution.mbt`、`conformance.mbt`、`catalog.mbt`、`baseline.mbt` |
| 84 组回归语料 | `regression_corpus.mbt` |
| 112 个测试 | 根目录 `*_test.mbt` 与 `*_wbtest.mbt` |
| 三个运行入口 | `cmd/main`、`examples/basic`、`examples/governance` |
| API、设计、测试和生态文档 | `docs/` |
| 持续集成 | `.github/workflows/ci.yml` |
| 公开接口快照 | `pkg.generated.mbti` |
| 作者与提交身份 | `AUTHORS.md` |

## 复现命令

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

## 开源合规

项目采用 OSI 认可的 Apache-2.0 许可证。格式与行为边界来自 RFC 7578、RFC 2046 和 RFC 8187 等公开规范；代码、测试、示例和 fixture 均为原创或项目自有合成内容，不包含来源不明、私有、闭源或商业代码。
