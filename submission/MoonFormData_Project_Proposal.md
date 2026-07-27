# MoonFormData 项目申报书

## 1. 项目名称和 GitHub 仓库地址

- 项目名称：MoonFormData：MoonBit 原生 multipart/form-data 表单解析与生成库
- GitHub 仓库地址：https://github.com/ouoankang/moonformdata

## 2. 项目简介

MoonFormData 是一个用 MoonBit 编写的 multipart/form-data 处理库，主要用于处理 HTTP 表单和文件上传请求。项目提供解析和生成 multipart body 的基础能力，方便接入 MoonBit HTTP 客户端、Webhook 工具、API 测试工具或 Web 框架。

项目不会实现完整 HTTP server，而是专注在表单体格式本身，给上层网络库和应用项目提供可以复用的基础组件。

## 3. 项目方向与适用场景

项目方向：MoonBit HTTP 表单处理基础库。

适用场景包括：
- 文件上传接口的请求体解析；
- Webhook 或 API 调试中的 multipart 数据读取；
- HTTP 客户端和测试工具生成 multipart 请求体；
- Web 框架、轻量网关等上层项目复用表单解析能力。

## 4. 拟实现的核心功能

- 从 Content-Type 中解析 boundary；
- 解析 multipart/form-data body，保留字段、文件、header、filename、content type 和 part 顺序；
- 支持普通字段、重复字段、同名多文件、空文件和自定义 part header；
- 生成 multipart body 和对应的 Content-Type；
- 提供安全文件名处理，避免直接使用带路径或控制字符的客户端文件名；
- 提供字段/文件查询、表单摘要、错误信息、校验策略和可运行示例；
- 提供 README、测试用例、CI 和 Mooncakes 发布配置。

## 5. 项目性质与开源说明

本项目为原创 MoonBit 开源项目，不是移植项目。项目不会直接复制其他语言生态中的 multipart/form-data 库代码。

项目实现会参考公开协议和通用 HTTP 行为，包括 RFC 7578、RFC 2046、RFC 2183、RFC 5987 等。项目采用 Apache-2.0 许可证，第三方参考资料只作为协议和行为依据，不作为代码来源。
