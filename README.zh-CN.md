# Bitsmith

**看懂、检查并编辑固件镜像的本地工作台。**

[English](README.md) · **简体中文**

[源码](https://github.com/turlamai/bitsmith) · [问题与反馈](https://github.com/turlamai/bitsmith/issues)

> **开发预览。** 引擎与桌面工作台已实现并有测试覆盖，并已发布开发预览安装包，但完整的跨平台安装验收仍未完成。生产固件必须独立复核后才能使用。目前不规划收费、试用到期或付费功能门禁。

## 解决什么问题

Intel HEX、Motorola S-record（S19/SREC）和原始 BIN 文件，应按**地址映像**处理，而不是按普通文本编辑。目标工作流：

1. 将输入解析为「地址 → 字节」模型，并解释每条记录。
2. 检查地址范围、空洞、重叠和记录校验。
3. 进行语义化修改，保存时重新生成记录与校验和。
4. 支持填充、偏移、裁剪、合并、转换和 CRC 等常见操作。

**交付状态：** 四个工作台视图（记录、镜像、操作、学习）已通过类型化桥接接到 Racket 引擎——解析、实时校验和、语义操作、格式转换、CRC 预设与文件打开/保存均已实现；已发布五种平台与架构组合的安装产物，完整安装验收尚未完成。

## 平台与安装

面向 macOS、Windows、Linux，Racket 领域引擎 + [Glaze](https://github.com/turlamai/glaze) 提供的系统 WebView UI。

### 从 release 安装

每个 [tagged release](https://github.com/turlamai/bitsmith/releases) 附带安装产物（deb/rpm/AppImage/Flatpak/tar.gz、DMG/zip、MSI/zip）。运行前先校验：

```bash
gh release download v<version> --repo turlamai/bitsmith --pattern 'bitsmith-<version>-macos-arm64.dmg'
gh release download v<version> --repo turlamai/bitsmith --pattern SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing
```

内置的 **检查更新**（记录视图侧栏底部）只做**通知**：它验证 Ed25519 签名的更新清单，自身不下载、不安装——下载与安装始终在你手里。

[v0.1.0 发布说明](https://github.com/turlamai/bitsmith/releases/tag/v0.1.0)记录了五个构建任务通过、更新清单签名验证及 macOS ARM64 DMG 启动冒烟通过。该版本 macOS 安装包仅采用临时签名，尚无 Developer ID 签名及公证；Linux 和 Windows 真机安装冒烟仍待完成。请以各版本发布说明的验证状态为准，未经完整验收的安装包按开发构建对待。

## 数据与隐私

目标是完全本地处理：固件不能被上传到在线转换器或云服务，核心流程不需要账号。修改后的文件必须另行验证格式、校验和与目标内存映射；务必保留原件和备份。

## 相关产品

[FlashPilot](https://github.com/turlamai/flashpilot) 负责声明式 ECU 刷写。Bitsmith 负责检查、准备镜像，FlashPilot 负责通过总线与 ECU 通信。

## 从源码构建

需要 [Racket](https://racket-lang.org/) 9.0+ 与 `glaze` 包（`raco pkg install --auto glaze`），以及 `crypto`（`raco pkg install --auto crypto`，更新检查需要）。

```bash
raco test shared/engine/   # 引擎单元测试（round-trip 已验证样例）
raco glaze schema check    # API 契约对照已评审基线
raco glaze verify          # 原生窗口验收：加载、断言、截图
racket main.rkt            # 运行桌面工作台
```

## 开发与反馈

在 [Issues](https://github.com/turlamai/bitsmith/issues) 提交**合成的**最小测试镜像，写明预期与实际地址/校验和及平台信息；不要上传保密生产固件。贡献规则与推送前要跑的检查见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

AGPL-3.0，见 [LICENSE](LICENSE)。安装包内随附的第三方组件见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。[全家族质量优先决策](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.zh-CN.md)不会更改现有源码许可。
