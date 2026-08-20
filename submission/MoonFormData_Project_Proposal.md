# MoonFormData 项目申报书

## 基本信息
- 项目名称：MoonFormData：MoonBit 原生 multipart/form-data 表单解析与生成库
- 申报人：安康
- 联系方式：15633022302
- GitHub 仓库：https://github.com/ouoankang/moonformdata
- Mooncakes 包：`ouoankang/moonformdata@0.1.0`（已发布）
- 项目方向：MoonBit HTTP 表单处理与上传契约治理工具
- 项目性质：原创 MoonBit 开源项目

## 项目简介
MoonFormData 使用 MoonBit 实现 `multipart/form-data` 请求解析、生成、命名 Schema、安全校验、风险分析和端点决策，并提供契约版本比较、一致性测试、多端点目录与回归基线。项目把文件上传从单次格式解析扩展为可校验、可演进、可追踪的 API 契约治理流程。

## 项目方向与适用场景
项目适用于文件上传端点、Webhook、轻量网关、HTTP 客户端、Web 框架集成和 API 回归测试。项目处理已获取的有界请求体，不承担完整 HTTP server、流式大文件传输、嵌套 multipart 和文件存储，功能边界清晰。

## 核心功能
- 解析和生成 boundary、part headers、普通字段、重复字段、同名多文件、空文件、`filename` 与 `filename*`；
- 提供字段/文件查询、Builder、结构化错误和安全文件名策略；
- 使用 `FormSchema` 与 `UploadContract` 校验必填项、数量、大小、类型、扩展名、未知项和风险阈值；
- 比较新旧契约，识别新增必填项、收紧限额、缩小白名单等破坏性变更；
- 批量验证接受、拒绝、解析失败、错误码和风险等级，并生成稳定 Markdown 报告；
- 管理多 HTTP 路由的版本化上传契约，保存和比较可复现行为基线；
- 提供 84 组回归语料、112 个测试、三个可运行示例、默认/JS 双目标检查和 GitHub Actions CI。

## 原创与生态差异
项目为独立原创实现，不是移植项目。Mooncakes 现有 `GCodinggo/moon-multipart` 和 `Songyz002/moon-multipart` 侧重 RFC 7578 字节流 parser/writer 与大文件传输；MoonFormData 处理字节拆包之后的应用层问题，提供命名 Schema、风险决策、API 版本兼容、一致性矩阵和回归基线。它可用于上传端点升级前检查破坏性变更、在 CI 中批量验证客户端样例、统一多路由策略并追踪行为漂移，实用范围与流式传输库互补而非重复。项目不依赖、复制或移植上述包，格式行为仅参考 RFC 7578、RFC 2046 和 RFC 8187 等公开规范，采用 Apache-2.0 许可证。
