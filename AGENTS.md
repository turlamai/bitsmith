# Bitsmith agent contract

## 家族设计（必读入口）

- 设计/UI 任务先加载 `tlai-product`，必读 `references/policy.md` 与 `references/design-standard.md`（理念、决策规则、UI 验收）。技能缺失时读取 ZCode 真源：macOS/Linux `~/Sync/ZCode/skills/tlai-product/`；Windows `D:/ZCode/skills/tlai-product/`。无法读取须报告规范未核验，不凭记忆跳过。
- 家族规范管共性；本仓现有设计、行为与 token 真源管具体值和产品差异。例外记回原契约，不复制家族规则或新增数值表；已有界面按下一次相关切片渐进对齐。
- 改界面先改原型、落账后实现；按家族 UI 清单与本仓当前技术线的既有门禁验收，原型对照和真实交互证据都要保留；对外宣传使用验收后的实物截图。

Professional firmware-image workbench, glaze line. Local by design.

Start with `raco glaze inspect --json`; run `raco glaze schema check --json`
before merging an API change.

## 实现路由（agent 按任务读真源）

- 实现界面以 `design/prototype/` 为准：对照 HTML/CSS/JS 与实物截图验收。
- Token/几何值真源 = `design/prototype/shared.css`；`design/DESIGN.md` 只记
  语义名、用途与决策。
- 引擎真源 = `shared/engine/`；范围与格式矩阵 = `shared/spec.md`。
- 改界面先改原型再改代码（tlai-product）；动共享层先 issue 声明。

## Verification floor

- `raco test shared/engine/` — engine unit tests; every checksum/CRC claim
  is round-trip verified against `shared/spec.md` samples (synthetic only).
- `raco glaze schema check --json` before merging an API change.
- `raco glaze verify` — native-window acceptance: opens the real WebView,
  asserts the workspace contract, walks all four views, captures PNGs.
- Frontend chrome strings live in `public/i18n.js` (en + zh tables keyed by
  `data-i18n`); engine-side explanation strings live in `shared/i18n/`.
  Both tables must stay key-aligned (中英同源).

## Release and update discipline

- 版本同值：仓库根 `VERSION` + `shared/engine/main.rkt` 的 `app-version` +
  `CHANGELOG.md` 顶部段；`bash scripts/check-release-version.sh`（tag 传参
  时校验 tag）进 CI 常跑。发布 = 同值 + annotated tag `v*`，轻量 tag 被
  validate 拒绝。
- 更新 feed 是 Ed25519 签名的 `update-manifest.json`（release 资产，
  `releases/latest/download/`），公钥嵌在 `shared/engine/updater.rkt`、
  私钥只在 CI secret 与 `~/Sync/Keys/secrets.ini` [bitsmith]——缺签名密钥
  release.yml 拒绝发版（fail-closed）；永不发未签名 feed。
- 发布后复检：SHA256SUMS 抽验 + updater 验证器 `verify-manifest-signature`
  验签 update-manifest.json。家族正典：termpilot（glaze 线 release 管线）。

## Domain rules

- 嵌入样例一律合成（`shared/spec.md` 有已验证清单），零公司/项目信息进仓。
- 任何进仓的 checksum/CRC 示例必须可验证（round-trip）。
- 解释文案是产品核心资产，不是注释：教学级质量，中英同源（i18n 键稳定）。
