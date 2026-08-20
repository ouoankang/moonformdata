# MoonFormData 项目申报书

## 基本信息

- 项目名称：MoonFormData：MoonBit 原生 multipart/form-data 表单解析与生成库
- 申报人：安康
- 联系方式：15633022302
- GitHub 仓库：https://github.com/ouoankang/moonformdata
- Mooncakes 包：`ouoankang/moonformdata`，版本 `0.1.0`
- 项目性质：原创 MoonBit 开源项目

## 项目简介

MoonFormData 使用 MoonBit 实现 multipart/form-data 内存解析、请求体生成、命名字段与文件 Schema、文件名安全治理、风险分析和上传契约验收。项目把完整请求体转换为有序表单模型，并统一输出接受/拒绝决策、校验原因和稳定诊断报告。

## 项目方向与适用场景

项目属于 MoonBit HTTP 表单处理与 API 质量工具，适用于文件上传端点、Webhook、轻量网关、HTTP 客户端、API 回归测试和 Web 框架集成。项目不实现完整 HTTP server、流式大文件传输、嵌套 multipart 或存储适配器，功能边界集中在已获取请求体的结构化验收与诊断。

## 已实现的核心功能

- 已实现 `Content-Type` boundary、`Content-Disposition`、part headers、`filename` 和 `filename*` 解析；
- 已支持普通字段、重复字段、同名多文件、空文件、自定义 header、CRLF 和 LF-only 请求体；
- 已实现 multipart encoder、Builder、字段/文件查询和结构化错误模型；
- 已实现路径分隔符、盘符、控制字符、危险扩展名和长度限制等文件名安全策略；
- 已实现 `ValidationPolicy`、`FormSchema`、`UploadContract` 和 `UploadInspection`，支持必填项、数量、大小、类型、扩展名、未知项和风险阈值校验；
- 已提供 84 组回归 fixture、81 个测试、两个可运行示例、默认/JS 双目标检查和 GitHub Actions CI；
- 已提供 README、API、设计、测试、生态差异、提交身份和验收说明。

## 原创与生态差异

项目为独立原创实现，不是移植项目。Mooncakes 现有 `GCodinggo/moon-multipart` 和 `Songyz002/moon-multipart` 的公开定位侧重 RFC 7578 字节流解析与 writer；MoonFormData 侧重应用层命名 Schema、未知项策略、风险阈值、上传验收决策和稳定诊断报告。项目与上述包不存在代码、fixture、依赖或移植关系。

实现仅以 RFC 7578、RFC 2046 和 RFC 8187 等公开协议作为格式与行为边界。测试数据与示例均为项目自有合成内容，项目采用 OSI 认可的 Apache-2.0 许可证。
