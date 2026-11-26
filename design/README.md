# design/ — 唯一设计真源

- `DESIGN.md`：品牌与交互契约，含设计原则、token 语义、不变式和验收条件。
- `index.html`：直接打开 Records 工作台的默认入口，随原型入库。
- `prototype/`：可交互 HTML、共享 CSS 与本地脚本，零外部运行依赖，支持亮暗主题。

本目录是原型唯一工作区：agent 直接在这里生成和改，浏览器预览，改到位 commit/push。换设备 clone 即接续，保留相对路径与运行依赖。不再生成或保留页面目录。改界面先改原型再改代码（tlai-product）。
