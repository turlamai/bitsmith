# ImageBench

**看懂并驾驭固件镜像——本地运行的 Intel HEX / Motorola S-record / BIN 工作台：记录级解释、语义化编辑（实时重算 checksum）、以及 FBL 开发者天天在做的操作（填充、偏移、裁剪、合并、转换、CRC）。**

[English](README.md) · 简体中文

状态：早期开发（原型阶段）。Racket 引擎 + 系统 WebView 驻留 UI（glaze 线）。桌面优先：macOS / Windows / Linux 三平台同等。**只在本机运行**——固件保密是产品原则，不是限制。

## 为什么做

FBL（Flash Bootloader）开发意味着天天面对 hex/s19/bin：通用十六进制编辑器编辑它们并不安全（它看到的是 ASCII 文本，不是内存映像，改一个字节 checksum 就作废）；CLI 工具套件功能全但选项记不住；在线转换器碰不得（固件保密红线）。ImageBench 把所有格式解析成同一个「地址 → 数据」模型：编辑发生在映像层，写回时自动重算 checksum 与记录结构，每个字段都能自我解释。

## 相关

[FlashPilot](https://github.com/turlamai/flashpilot)——工作流的刷写端：声明式 flash plan 驱动的 UDS over CAN/DoIP/LIN。ImageBench 负责把镜像备好，FlashPilot 负责刷进去。

## 许可

AGPL-3.0，见 [LICENSE](LICENSE)。
