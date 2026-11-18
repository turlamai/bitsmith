# Binlet

> Formerly **ImageBench**. The public repository URL remains under `turlamai/imagebench` until the repository slug is renamed in GitHub settings.

**看懂、检查并编辑固件镜像的本地工作台。**

[English](README.md) · **简体中文**

[产品主页](https://jrtx.site/products/binlet/) · [源码](https://github.com/turlamai/imagebench) · [问题与反馈](https://github.com/turlamai/imagebench/issues)

> **开发预览——原型阶段。** Binlet 尚不是可用于生产的编辑器，也没有经过验证的安装包。生产固件必须独立复核后才能使用。目前不规划收费、试用到期或付费功能门禁。

## 解决什么问题

Intel HEX、Motorola S-record（S19/SREC）和原始 BIN 文件，应按**地址映像**处理，而不是按普通文本编辑。目标工作流：

1. 将输入解析为「地址 → 字节」模型，并解释每条记录。
2. 检查地址范围、空洞、重叠和记录校验。
3. 进行语义化修改，保存时重新生成记录与校验和。
4. 支持填充、偏移、裁剪、合并、转换和 CRC 等常见操作。

**交付状态：** 上述是产品方向，仓库仍在早期原型阶段，不能据此断言所有操作或三平台宿主已实现。

## 平台与使用

目标平台为 macOS、Windows 和 Linux，使用 Racket 领域引擎及 [Glaze](https://github.com/turlamai/glaze) 系统 WebView UI。**当前没有完成验证的原生安装包和干净安装流程。** 请查看[源码](https://github.com/turlamai/imagebench)与[设计资料](design/)，不要将未验证的构建用于正式固件。

## 数据与隐私

目标是完全本地处理：固件不能被上传到在线转换器或云服务，核心流程不需要账号。修改后的文件必须另行验证格式、校验和与目标内存映射；务必保留原件和备份。

## 相关产品

[FlashPilot](https://github.com/turlamai/flashpilot) 负责声明式 ECU 刷写。Binlet 负责检查、准备镜像，FlashPilot 负责通过总线与 ECU 通信。

## 开发与反馈

在 [Issues](https://github.com/turlamai/imagebench/issues) 提交**合成的**最小测试镜像，写明预期与实际地址/校验和及平台信息；不要上传保密生产固件。

## 许可证

AGPL-3.0，见 [LICENSE](LICENSE)。[全家族质量优先决策](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.zh-CN.md)不会更改现有源码许可。
