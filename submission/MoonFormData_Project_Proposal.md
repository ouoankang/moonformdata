# MoonFormData 项目申报书

## 基本信息

项目名称：MoonFormData：MoonBit 原生 multipart/form-data 表单解析与生成库

参赛者：安康

联系方式：15633022302

GitHub 仓库链接：https://github.com/ouoankang/moonformdata

项目方向：MoonBit HTTP 表单处理基础库 / Web 与 API 工具链基础设施

是否为移植项目：否

## 项目简介

MoonFormData 计划在 MoonBit 生态中提供一套可复用的 multipart/form-data 表单处理能力，主要面向文件上传、Webhook、API 测试、HTTP 客户端、轻量网关和 Web 框架集成等场景。项目重点解决 MoonBit 项目中处理 multipart 请求体时缺少独立基础库的问题，使开发者可以直接解析表单字段和上传文件，也可以生成符合常见 HTTP 使用方式的 multipart 请求体。

本项目不实现完整 HTTP server，也不绑定具体 Web 框架，而是专注于 multipart/form-data 格式本身，作为上层 MoonBit 网络库、工具库和应用项目可以复用的基础组件。

## 核心功能范围

提供 Content-Type 中 boundary 参数的解析与校验能力；

支持 multipart/form-data body 的解析，保留普通字段、文件字段、part headers、filename、content type 和原始 part 顺序；

支持普通字段、重复字段、同名多文件、空文件和自定义 part header 等常见表单场景；

提供 multipart body 生成功能，方便 HTTP 客户端、Webhook 调试和 API 测试构造请求体；

提供安全文件名处理，避免直接使用带路径、盘符、控制字符或危险扩展名的客户端文件名；

提供字段查询、文件查询、必填字段读取、表单摘要、错误信息格式化和调试输出；

提供 ValidationPolicy 和 FormSchema，用于检查必填字段、必填文件、文件类型、大小限制、重复字段和未知字段；

提供 README 示例、可运行 examples、测试用例和 GitHub Actions CI，便于项目验收和后续维护。

## 原创或参考说明

本项目为原创 MoonBit 开源项目，不是移植项目。项目不会直接复制或移植其他语言生态中的 multipart/form-data 库代码。

项目实现会参考 multipart/form-data 和 HTTP 表单处理相关公开规范与通用行为，包括 RFC 7578、RFC 2046、RFC 2183、RFC 5987 等。上述资料仅作为协议格式和行为边界参考，不作为代码来源。

本项目采用 Apache-2.0 开源许可证。项目中使用的测试数据和示例数据均为自行构造，不包含私有代码、闭源代码或来源不明内容。
