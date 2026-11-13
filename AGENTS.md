# ImageBench agent contract

Professional firmware-image workbench, glaze line. Local by design.

Start with `raco glaze inspect --json`; run `raco glaze schema check --json`
before merging an API change.

## 实现路由（agent 按任务读真源）

- 实现界面以 `design/prototype/` 为准：对照 HTML/CSS/JS 与实物截图验收。
- Token/几何值真源 = `design/prototype/shared.css`；`design/DESIGN.md` 只记
  语义名、用途与决策。
- 引擎真源 = `shared/engine/`；范围与格式矩阵 = `shared/spec.md`。
- 改界面先改原型再改代码（tlai-prototype-flow）；动共享层先 issue 声明。

## Domain rules

- 嵌入样例一律合成（`shared/spec.md` 有已验证清单），零公司/项目信息进仓。
- 任何进仓的 checksum/CRC 示例必须可验证（round-trip）。
- 解释文案是产品核心资产，不是注释：教学级质量，中英同源（i18n 键稳定）。
