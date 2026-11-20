// Bitsmith UI i18n: chrome strings live here (en + zh); engine-side
// explanation strings arrive from api/i18n/strings and land in
// window.BitsmithEngineStrings. Static elements carry data-i18n
// (textContent) or data-i18n-html (innerHTML for composed copy); dynamic
// strings call BitsmithI18n.t().
//
// Language preference persists in localStorage; detection mirrors the
// product site (navigator.language, zh preferred).

(function () {
  'use strict';

  const zh = {
    'nav.records': '记录',
    'nav.image': '镜像',
    'nav.operations': '操作',
    'nav.learn': '学习',
    'topbar.local': '仅本地',
    'btn.open': '打开固件',
    'btn.save': '保存',
    'btn.choose-file': '选择文件…',
    'btn.restore-sample': '恢复样例镜像',
    'btn.jump-fail': '跳到失败项',
    'btn.verify-all': '全部校验',
    'btn.go': '跳转',
    'btn.base-details': '基址详情',
    'btn.back-to-preview': '返回预览',
    'btn.apply-working': '应用到工作副本',
    'btn.reset-sample': '重置样例',
    'btn.review-apply': '核对并应用',

    'source.eyebrow': '源文件 · 内容识别',
    'source.sniffed': '按内容识别；扩展名为',
    'source.no-extension': '无扩展名',
    'source.no-data-records': '无数据记录',
    'meta.address-range': '地址范围',
    'meta.data-bytes': '数据字节',
    'meta.records': '记录数',
    'meta.detected': '识别为',
    'meta.base': '基址',
    'meta.recorded': '已记录',
    'meta.span': '跨度',

    'verify.ok-head': '条记录通过',
    'verify.failed': '条失败',
    'segments.label': '分段',
    'segments.gap-list': '间隙列表',
    'segments.no-gaps': '数据范围之间没有间隙',
    'segments.explicit-ff': '显式 0xFF',
    'sidebar.sample-note': 'APP 起始于基址偏移 0x8000。最后一个 FBL 字节与第一个 APP 字节之间是 0x7FE0 字节的间隙。',
    'sidebar.bin-note': 'BIN 无法证明自己的加载地址。下方基址是本次会话的当前工作假设。',
    'field.base-readout': '假定基址',
    'field.base-help': 'BIN 基址是显式设定。Intel HEX 记录自带绝对地址。',
    'sidebar.foot.workbench': '内容优先 · 直接操纵',
    'sidebar.foot.absolute': '地址均为绝对地址',
    'empty.no-file': '未打开文件',
    'empty.copy': '打开一个 Intel HEX、S-record 或 BIN 文件来查看记录。格式由内容识别决定；扩展名只是提示。',
    'empty.title': '打开固件镜像',
    'empty.drop-copy': '把 Intel HEX、Motorola S-record 或 raw BIN 文件拖到这里。Bitsmith 按内容识别——扩展名会说谎，真实文件常常没有扩展名。',
    'empty.bin-title': '这个 BIN 没有记录',
    'empty.bin-copy': '二进制镜像不携带地址或记录结构。字节仍可在镜像视图中查看，基址在其中被显式当作假设处理。',
    'empty.formats': 'Intel HEX · S-record · BIN',
    'drop.formats-hint': '拖入文件或点击选择',

    'view.records': '记录视图',
    'view.image': '镜像视图',
    'view.operations': '操作',
    'view.learn': '学习',
    'toolbar.records-suffix': '条记录 · 实时校验和',
    'toolbar.working-copy': '工作副本',
    'toolbar.dump-sub': '地址真实的十六进制转储',
    'status.no-file': '未打开文件',
    'status.no-file-loaded': '未加载文件',
    'status.records': '记录',
    'status.checksum': '校验和',
    'status.ascii': 'ASCII · 一行一条记录',
    'status.esc': 'Esc 关闭弹层',
    'status.encoding': '8-bit · ASCII 侧栏 · 每行 16 B',
    'status.cursor': '光标',
    'status.selection': '选区',
    'status.basis-hex': 'HEX · 记录地址',
    'status.basis-bin': 'BIN · 基址为假设',
    'status.revision': '版本',
    'status.gate': '门禁',
    'status.views': '视图',

    'summary.data-bytes': '数据字节',
    'summary.first-address': '首地址',
    'summary.last-address': '末地址',
    'summary.valid': '有效',

    'legend.type-data': 'Data',
    'legend.type-eof': 'EOF',
    'legend.type-es': 'Ext segment',
    'legend.type-ss': 'Start segment',
    'legend.type-04': 'Ext linear',
    'legend.type-sl': 'Start linear',

    'th.index': '#',
    'th.raw': '原始行',
    'th.bytes': '字节',
    'th.address': '地址',
    'th.absolute': '绝对地址',
    'th.type': '类型',
    'th.data': '数据',
    'th.checksum': '校验',
    'th.verdict': '判定',

    'record.malformed': '格式损坏',
    'record.type-04': 'Ext linear',
    'record.verdict-ok': 'OK',
    'record.verdict-fail': '失败',
    'record.math-label': '校验和计算',
    'record.twos-complement': '二进制补码',
    'record.expected-found': '期望 · 实际',
    'record.fail-tag': '失败',

    'table.note': '绝对地址列由当前生效的扩展地址记录推导。悬停记录类型查看精简图例；打开记录 01 阅读完整的 04 解释。',
    'inspector.title': '记录检查器',
    'inspector.byte-title': '字节检查器',
    'inspector.no-selection': '未选中记录',
    'inspector.choose-record': '选择一条记录以查看其字段与实时校验和。',
    'inspector.open-first': '打开文件后即可检查记录。',
    'inspector.record-n': '记录',
    'inspector.verified': '已验证',
    'inspector.failed': '失败',
    'inspector.payload': '载荷',
    'inspector.bytes': '字节',
    'inspector.file-verification': '文件校验',
    'inspector.check-verifies': '该记录校验通过',
    'inspector.check-fails': '该记录校验失败',
    'inspector.check-decoded': '字段已从原始行解码',
    'inspector.check-absolute': '绝对地址已由当前基址推导',
    'inspector.selected-byte': '选中字节',
    'inspector.no-byte': '未选中字节',
    'inspector.click-byte': '点击一个字节查看其地址与取值。',
    'inspector.selection': '选区',
    'inspector.non-printable': '不可打印',
    'inspector.range-active': '范围选区已激活。Shift 点击另一个字节可扩展或反转范围。',
    'inspector.range-hint': 'Shift 点击另一个字节可选择地址范围。',
    'inspector.basis-title': '地址依据',
    'inspector.map-title': '地图表达的内容',

    'kv.type': '类型',
    'kv.byte-count': '字节数',
    'kv.record-address': '记录地址',
    'kv.absolute': '绝对地址',
    'kv.stored': '存储校验',
    'kv.expected': '期望值',
    'kv.address': '地址',
    'kv.segment': '分段',
    'kv.offset': '偏移',
    'kv.row': '所在行',
    'kv.ascii': 'ASCII',
    'kv.start': '起点',
    'kv.end': '终点',
    'kv.basis': '依据',
    'basis.hex': 'HEX 记录',
    'basis.bin': 'BIN 基址',
    'basis.assumed': '假设',
    'basis.recorded': '记录值',

    'map.segment-map': '分段地图',
    'map.empty': '尚无已占用字节',
    'map.tip-data': '数据记录；校验和已验证。',
    'map.tip-gap': '该范围没有数据记录。与显式 0xFF 填充不同。',
    'map.note-hex': '真实比例显示跨度。地址来自记录本身（含 type 04 基址）。斜纹区域是间隙，不是已擦除数据。',
    'map.note-bin': '真实比例显示跨度。基址是本次会话的假设。斜纹区域是间隙，不是已擦除数据。',
    'map.check-gaps': '间隙没有记录',
    'map.check-ff': '显式 0xFF 是真实数据',
    'map.check-absolute': '地址均为绝对地址',
    'legend.fbl': 'FBL',
    'legend.app': 'APP',
    'legend.gap': '间隙',
    'legend.ff': '显式 0xFF',
    'legend.cursor': '光标 / 选区',

    'skip.gap': '间隙',
    'skip.no-records': '· 无数据记录',

    'hex.title': '十六进制转储 · 绝对地址',
    'hex.rows-badge': '16 字节 / 行',
    'hex.address': '地址',
    'hex.ascii': 'ASCII',

    'file.subline-hex': 'Intel HEX——地址来自扩展地址记录',
    'file.subline-bin': 'Raw BIN——没有地址记录；基址是假设',
    'file.rows': '行',

    'pop.04.title': '记录类型 04 — Extended Linear Address',
    'pop.04.sub': '为后续数据记录设置高 16 位地址。',
    'pop.04.why-title': '它为什么存在。',
    'pop.04.why': '数据记录只携带 16 位地址，而 flash 常位于 32 位地址空间。类型 04 补上缺失的高位。',
    'pop.04.derive': '下一个位于低地址 0x0000 的数据记录，其绝对地址就是 0x08000000。',
    'pop.04.affects': '影响',
    'pop.04.affects-v': '所有后续数据记录',
    'pop.04.until': '直到',
    'pop.04.until-v': '另一条 02 / 04 或 EOF',
    'pop.04.record-data': '记录数据',
    'pop.04.record-data-v': '2 字节，大端基址',
    'pop.04.type02': '类型 02 是更旧的分段形式：基址只移 4 位。两者并存是因为工具链与传统编程器仍在输出它们。',
    'pop.04.foot': 'Esc 关闭 · 点击其他类型徽章查看解释',
    'pop.byte-title': '字节位于',
    'pop.byte-sub': '按绝对地址从镜像中读取。',
    'pop.byte-hero': '十六进制字节',
    'pop.dec-suffix': 'dec',
    'pop.byte-note': '字节取值是精确的。对 BIN 导入而言，其地址只与当前基址假设一样精确。',
    'pop.byte-foot': 'Esc 关闭 · Shift 点击选择范围',

    'banner.bin-title': 'BIN 不携带地址信息——下方基址是你设定的假设',
    'banner.bin-detail': '未找到地址记录。Bitsmith 按当前工作基址显示字节。写入前请对照设备内存映射核对该基址。',

    'switch.bin-label': 'BIN 状态',
    'goto.label': '前往地址',

    'ops.detail-hint': '编辑参数，检查前后效果，然后应用到工作副本。',
    'ops.parameters': '参数',
    'ops.absolute-addresses': '绝对地址',
    'ops.preview-title': '前后对比预览',
    'ops.preview-note': '按参数重算',
    'ops.preview-blocked': '预览不可用',
    'ops.reset-sample': '重置样例',
    'ops.review-apply': '核对并应用',
    'ops.confirm-tail': '源文件保持不变。',
    'ops.shared-scale': '共享线性标尺 · 间隙未映射',
    'ops.unmapped': '未映射',
    'ops.populated': '已占用',
    'ops.affected-records': '受影响记录',
    'ops.no-record-change': '记录字节没有变化。',
    'ops.canonical-note': '规范输出对比；最多显示四条移除与四条新增。',
    'ops.affected-bytes': '受影响字节',
    'ops.first-12': '仅显示前 12 个受影响字节。',
    'ops.canonical-counts': '规范 HEX 记录数：',
    'ops.gate-blocked': '门禁阻断',
    'ops.gate-readonly': '只读',
    'ops.gate-ready': '预览就绪',
    'ops.blocked': '阻断',
    'ops.ready': '就绪',
    'ops.gate-retained': '绝对地址保持不变。参数已预览。应用需要确认。',
    'ops.apply-blocked': '应用被阻断',
    'ops.digest-computed': '摘要已计算',
    'ops.preview-ready': '预览就绪',
    'ops.resolve-conflict': '解决冲突以启用应用',
    'ops.working-copy-only': '仅工作副本',
    'ops.session-note': '版本',
    'ops.session-note-2': '应用提交当前预览；重置恢复样例。改动只影响本会话。',
    'ops.affected-title': '应用门禁',
    'ops.scope-title': '范围',
    'ops.why-title': '这个门禁为何存在',
    'ops.why-copy': '冲突不是可以点掉的警告。它是两段输入镜像的重叠。应用之前请把目标基址改到不重叠的地址范围。',
    'ops.session-title': '会话',
    'ops.confirm-title': '应用该预览？',
    'ops.working-copy': '工作副本',
    'ops.apply-failed': '应用失败',
    'crc.computed': '计算',
    'crc.live': '实时 · 不做比对',

    'scope.source': '源',
    'scope.format': '格式',
    'scope.revision': '版本',
    'scope.populated': '已占用字节',
    'scope.span': '跨度',

    'toast.every-verifies': '全部记录校验通过',
    'toast.of': '/',
    'toast.verified-suffix': '条记录已验证 · 从字节重算',
    'toast.records-loaded': '条记录 · 内容识别为',
    'toast.unreadable': '无法读取该文件',
    'toast.enter-address': '请输入十六进制地址，例如 0x08008000',
    'toast.no-byte': '该地址没有已记录字节：',
    'toast.row-no-byte': '该行在此偏移没有字节：',

    'learn.back': '返回记录',
    'learn.on-this-page': '本页内容',
    'learn.sections-label': '节',
    'learn.sample-intro-html': '贯穿全页的样例是 <code>FBL_APP_combined.dat</code>：8 条 Intel HEX 记录，其中 7 条通过校验。',
    'learn.reference': '参考',
    'learn.reference-sub': '视图背后的规则。',
    'learn.intro': 'Bitsmith 里没有任何魔法：记录就是一条带小型算术契约的文本行，地址要么写在文件里，要么由你来假设。以下六节把这两个事实展开成你能亲手验证的算术。',
    'learn.s1': '01 · 记录到底是什么',
    'learn.s1-intro': '一条 Intel HEX 行是一个完整、自描述的包。Count 说明后面跟多少个数据字节；address 说明它们加载到哪里；type 说明这一行是什么性质；末尾一个字节把前面的算术封口。',
    'learn.failing-field-by-field': '失败记录逐字段拆解',
    'learn.f1-title': '计数 · 04',
    'learn.f1-body': '后面跟四个数据字节。一行不是随便的十六进制串；计数定义了它的形状。',
    'learn.f2-title': '地址 · 8020',
    'learn.f2-body': '当前 64 KiB 页内的偏移。上方的 type 04 记录提供高位。',
    'learn.f3-title': '类型 · 00',
    'learn.f3-body': '00 是数据。01 结束文件，02 与 04 扩展地址，03 与 05 是起始地址。',
    'learn.f4-title': '数据 · 48 B1 08 47',
    'learn.f4-body': '四个载荷字节原样保留；它们的指令含义取决于目标架构。',
    'learn.f5-title': '校验 · 00',
    'learn.f5-body': '存储值。这个是错的：算术结果应为 14。这就是样例中唯一失败的记录。',
    'learn.absolute-note-html': '该记录占用绝对地址 <span class="mono">0x08008020</span>，因为先前的 <span class="mono">:020000040800F2</span> 行把高 16 位设成了 <span class="mono">0x0800</span>。没有那一行，地址只会是 <span class="mono">0x8020</span>。',
    'learn.s7-title': 'S7 终止记录 · 逐字节',
    'learn.s7-f1-title': '类型 · S7',
    'learn.s7-f1-body': '终止一条 S3 流并携带 32 位执行地址。',
    'learn.s7-f2-title': '计数 · 05',
    'learn.s7-f2-body': '后面跟五个字节：四个地址字节加一个校验字节。',
    'learn.s7-f3-title': '地址 · 00 00 00 00',
    'learn.s7-f3-body': '执行地址是 0x00000000；这是元数据，不是数据写入。',
    'learn.s7-f4-title': '数据 · 无',
    'learn.s7-f4-body': 'S7 没有载荷；S1、S2、S3 携带数据，地址宽度分别为 16、24、32 位。',
    'learn.s7-f5-title': '校验 · FA',
    'learn.s7-f5-body': '计数加地址字节的反码收尾这条记录。',
    'learn.hover-hint-html': '悬停或聚焦任意字节查看其角色。精确输入是 <span class="mono">S70500000000FA</span>。',
    'learn.s2': '02 · 校验和是怎么算出来的',
    'learn.s2-intro': 'Intel HEX 使用二进制补码校验。把冒号之后、校验字节之前的每个字节相加，保留低字节，取补码再加一。结果与行尾字节相等则校验通过。',
    'learn.intel-playground': 'Intel HEX 记录 · 修改字节实时重算',
    'learn.srec-playground': 'S-record · 反码',
    'learn.s2-outro': 'Bitsmith 在每次加载时对每一行重算。校验失败不会隐藏数据：记录保留在表格中，由你决定修复还是拒绝。',
    'learn.s3': '03 · 间隙不是字节',
    'learn.s3-intro': '记录流中缺失的范围与被 0xFF 填充的范围不是一回事。一个是信息的缺失；另一个是对设备的显式陈述。',
    'learn.gap-title': '间隙',
    'learn.gap-body-html': '没有记录覆盖该范围。地图把它画成空的斜纹条，工具拒绝假装知道那里是什么。样例中 <span class="mono">0x08000020–0x08007FFF</span> 的 32,736 字节就是这样的间隙。',
    'learn.ff-title': '显式 0xFF',
    'learn.ff-body-html': '某条记录真实地包含 0xFF 字节。样例在 <span class="mono">0x08009FF0</span> 有 16 个这样的字节。它们可以被校验、编辑与比对，因为它们存在于文件中。',
    'learn.s3-outro': '擦除操作会把覆盖的字节变成显式 0xFF 记录；填充操作也能把间隙实体化。两者都是写操作，走同一个确认门禁。',
    'learn.s4': '04 · HEX、S-record、BIN',
    'learn.s4-intro-html': '容器决定文件能证明多少。内容靠嗅探而不是扩展名——改名为 <span class="mono">.bin</span> 的固件仍然是文本记录。',
    'learn.tbl.property': '属性',
    'learn.tbl.address': '文件内地址',
    'learn.tbl.address-hex': '有——16 位加 02/04 扩展',
    'learn.tbl.address-srec': '有——记录内 16/24/32 位',
    'learn.tbl.address-bin': '没有——只有字节',
    'learn.tbl.checksum': '行校验',
    'learn.tbl.checksum-hex': '二进制补码（低字节）',
    'learn.tbl.checksum-srec': '反码（低字节）',
    'learn.tbl.checksum-bin': '无',
    'learn.tbl.eof': '文件结束',
    'learn.tbl.eof-hex': ':00000001FF',
    'learn.tbl.eof-srec': '终止记录 S7/S8/S9',
    'learn.tbl.eof-bin': '仅 EOF',
    'learn.tbl.overhead': 'ASCII 开销',
    'learn.tbl.overhead-text': '短行宽下约 3×；随数据长度变化',
    'learn.tbl.overhead-bin': '1× 载荷；填充可能增大体积',
    'learn.tbl.use': '典型用途',
    'learn.tbl.use-hex': 'MCU 工具链与稀疏 flash 镜像',
    'learn.tbl.use-srec': '汽车 / FBL 镜像交换；.s19 常见',
    'learn.tbl.use-bin': '连续 flash 转储与直接编程',
    'learn.tbl.risk': '主要风险',
    'learn.tbl.risk-hex': '忽视扩展地址记录或重叠',
    'learn.tbl.risk-srec': 'S1/S2/S3 宽度或计数解读错误',
    'learn.tbl.risk-bin': '基址错误、静默间隙填充、无逐行校验',
    'learn.tbl.editable': '可按文本编辑',
    'learn.tbl.editable-yes': '可以',
    'learn.tbl.editable-no': '不可以',
    'learn.tbl.base': '需要基址',
    'learn.tbl.base-no': '不需要',
    'learn.tbl.base-yes': '需要——一个假设',
    'learn.tbl.session': '本会话中',
    'learn.tbl.session-hex': '样例文件 · 已记录',
    'learn.tbl.session-srec': '支持 · 已记录',
    'learn.tbl.session-bin': '支持 · 假设基址',
    'learn.s4-outro-html': 'S-record 的计数包含地址与校验字节，而 Intel HEX 的计数只覆盖数据。补码方式也不同：反码对补码。打开学习页的实时算术即可亲手验证两者。',
    'learn.sources-title': '样例源记录 · 原样保留',
    'learn.s5': '05 · BIN 为什么需要基址',
    'learn.s5-intro': '裸二进制不知道自己属于内存的哪个位置。Bitsmith 不悄悄猜：它要求一个基址，并把下游每个地址都标记为该选择的产物。',
    'learn.s5-example': '基址 0x08000000 时，APP 写到 0x08008000。基址 0x00000000 时，同样的字节写到 0x00008000。',
    'learn.s5-outro': '字节从未移动；移动的是解读。这就是假定基址显示在每一屏上的原因，也是为什么更改它会重画整张地图而不是悄悄偏移。',
    'learn.s5-see-bin': '查看 BIN 状态',
    'learn.s5-note': '样例是 Intel HEX，因此没有发明基址。BIN 状态的存在是为了让假设可见：它是一个工作选择，不是文件的属性。',
    'learn.s6': '06 · 写入之前',
    'learn.s6-intro': '读取是廉价的；写入不是。这些是 Bitsmith 按重要性顺序摆在你面前的检查。',
    'learn.s6-1-title': '每条记录都通过校验，或者你清楚原因',
    'learn.s6-1-body': '样例有七条通过校验的记录和一条带算术展示的失败记录。失败的记录永远不会被悄悄修复。',
    'learn.s6-2-title': '你清楚哪些地址是记录在案的',
    'learn.s6-2-body': 'Intel HEX 与 S-record 自带地址。BIN 基址是假设，并且始终如此标注。',
    'learn.s6-3-title': '每个重叠都有明确的先后',
    'learn.s6-3-body': '声明相同字节的操作会产生冲突。解决冲突即记录哪个意图获胜；它从不掩盖重叠本身。',
    'learn.s6-4-title': '不应用就不落盘',
    'learn.s6-4-body': '操作只改变本会话的工作副本。磁盘上的源文件保持原样；冲突未决时门禁保持关闭。',
    'learn.foot.sample': '样例 · 8 条记录 · 7 条通过',
    'learn.foot.hex': 'Intel HEX · 记录地址',
    'learn.foot.hint': '内容优先 · 扩展名只是提示',

    'status.content-sniffed': '· 按内容识别',
    'status.esc-suffix': '关闭弹层',
    'pop.04.foot-suffix': '关闭 · 点击其他类型徽章查看解释',
    'empty.side-open': '<strong>未打开文件</strong>打开一个 Intel HEX、S-record 或 BIN 文件来查看记录。格式由内容识别决定；扩展名只是提示。',
    'pop.04.why-html': '<strong>它为什么存在。</strong>数据记录只携带 16 位地址，而 flash 常位于 32 位地址空间。类型 04 补上缺失的高位。',
    'pop.04.derive-html': '<span class="mono" style="color:var(--text)">0x0800 &lt;&lt; 16 = 0x08000000</span>。下一个位于低地址 0x0000 的数据记录，其绝对地址就是 <span class="mono" style="color:var(--text)">0x08000000</span>。',
    'toast.save-cancelled': '已取消保存',
    'toast.saved': '已保存',
    'toast.save-failed': '保存失败',
    'toast.open-cancelled': '未选择文件',
    'toast.loaded-failed': '无法解码该文件',
    'toc.1': '记录解剖',
    'toc.2': '校验和算术',
    'toc.3': '间隙不是字节',
    'toc.4': 'HEX、S-record、BIN',
    'toc.5': '假设的基址',
    'toc.6': '写入之前',
    'learn.sections-count': '6 节',
    'learn.s3-intro-html': '记录流中缺失的范围与被 <span class="mono">0xFF</span> 填充的范围不是一回事。一个是信息的缺失；另一个是对设备的显式陈述。',
    'learn.tbl.intel-h': 'Intel HEX',
    'learn.tbl.srec-h': 'S19 / S-record',
    'learn.tbl.bin-h': 'Raw BIN',
    'learn.tbl.intel': 'Intel HEX',
    'learn.tbl.srec': 'Motorola S-record',
    'ops.inspect-bytes': '检查字节',
    'ops.operation-label': '操作',
    'ops.staged': '暂存',
    'ops.conflicts': '冲突',
    'status.recorded-hex': '记录地址 · Intel HEX',
    'scope.target': '目标',
    'scope.working-copy': '工作副本',
    'ops.session-note-static': '改动只留在本会话。重置恢复样例。',
    'source.eyebrow-image': '源 · 地址依据',
    'pop.byte-foot-suffix': '关闭 · Shift 点击选择范围',
    'legend.fbl-data': 'FBL 数据',
    'legend.app-data': 'APP 数据',
    'legend.gap-nr': '间隙 / 无记录',
    'anatomy.intel.colon': '起始标记',
    'anatomy.intel.count': '数据字节计数',
    'anatomy.intel.addr-high': '地址高字节',
    'anatomy.intel.addr-low': '地址低字节',
    'anatomy.intel.type': '数据记录类型',
    'anatomy.intel.data-1': '载荷字节 1',
    'anatomy.intel.data-2': '载荷字节 2',
    'anatomy.intel.data-3': '载荷字节 3',
    'anatomy.intel.data-4': '载荷字节 4',
    'anatomy.intel.checksum': '存储的校验字节',
    'anatomy.srec.type': '32 位终止记录',
    'anatomy.srec.count': '地址加校验的计数',
    'anatomy.srec.addr-1': '执行地址字节 1',
    'anatomy.srec.addr-2': '执行地址字节 2',
    'anatomy.srec.addr-3': '执行地址字节 3',
    'anatomy.srec.addr-4': '执行地址字节 4',
    'anatomy.srec.checksum': '存储的校验字节',
    'update.check': '检查更新',
    'update.failed': '更新检查失败',
    'theme.to-light': '切换浅色主题',
    'theme.to-dark': '切换深色主题',
    'lang.switch': '语言'
  };

  const en = {
    'nav.records': 'Records',
    'nav.image': 'Image',
    'nav.operations': 'Operations',
    'nav.learn': 'Learn',
    'topbar.local': 'Local only',
    'btn.open': 'Open firmware',
    'btn.save': 'Save',
    'btn.choose-file': 'Choose file…',
    'btn.restore-sample': 'Restore sample image',
    'btn.jump-fail': 'Jump to failure',
    'btn.verify-all': 'Verify all',
    'btn.go': 'Go',
    'btn.base-details': 'Base details',
    'btn.back-to-preview': 'Back to preview',
    'btn.apply-working': 'Apply to working copy',
    'btn.reset-sample': 'Reset sample',
    'btn.review-apply': 'Review and apply',

    'source.eyebrow': 'Source file · content detected',
    'source.sniffed': 'sniffed by content; extension was',
    'source.no-extension': 'no extension',
    'source.no-data-records': 'No data records',
    'meta.address-range': 'Address range',
    'meta.data-bytes': 'Data bytes',
    'meta.records': 'Records',
    'meta.detected': 'Detected',
    'meta.base': 'Base',
    'meta.recorded': 'Recorded',
    'meta.span': 'Span',

    'verify.ok-head': 'records OK',
    'verify.failed': 'FAILED',
    'segments.label': 'Segments',
    'segments.gap-list': 'Gap list',
    'segments.no-gaps': 'No gaps between data ranges',
    'segments.explicit-ff': 'Explicit 0xFF',
    'sidebar.sample-note': 'APP starts at base offset 0x8000. The gap is 0x7FE0 bytes between the last FBL byte and the first APP byte.',
    'sidebar.bin-note': 'A BIN cannot prove its load address. The base below is the current working assumption for this session.',
    'field.base-readout': 'Assumed base address',
    'field.base-help': 'BIN base is explicit. Intel HEX records supply their own absolute addresses.',
    'sidebar.foot.workbench': 'Content first · direct manipulation',
    'sidebar.foot.absolute': 'Addresses are absolute',
    'empty.no-file': 'No file open',
    'empty.copy': 'Open an Intel HEX, S-record, or BIN file to inspect its records. Content sniffing decides the format; the extension is only a hint.',
    'empty.title': 'Open a firmware image',
    'empty.drop-copy': 'Drop an Intel HEX, Motorola S-record, or raw BIN file here. Bitsmith sniffs the content — extensions lie, and real-world files often arrive extensionless.',
    'empty.bin-title': 'This BIN has no records',
    'empty.bin-copy': 'Binary images carry no address or record structure. The bytes can still be viewed in Image view, where the base address is explicitly treated as an assumption.',
    'empty.formats': 'Intel HEX · S-record · BIN',

    'view.records': 'Record view',
    'view.image': 'Image view',
    'view.operations': 'Operations',
    'view.learn': 'Learn',
    'toolbar.records-suffix': 'records · live checksum verification',
    'toolbar.working-copy': 'Working copy',
    'toolbar.dump-sub': 'Address-true hex dump',
    'status.no-file': 'No file',
    'status.no-file-loaded': 'No file loaded',
    'status.records': 'Records',
    'status.checksum': 'Checksum',
    'status.ascii': 'ASCII · one record per line',
    'status.esc': 'Esc close popovers',
    'status.encoding': '8-bit · ASCII gutter · 16 B/row',
    'status.cursor': 'Cursor',
    'status.selection': 'Selection',
    'status.basis-hex': 'HEX · recorded addresses',
    'status.basis-bin': 'BIN · base assumed',
    'status.revision': 'revision',
    'status.gate': 'Gate',
    'status.views': 'views',

    'summary.data-bytes': 'data bytes',
    'summary.first-address': 'first address',
    'summary.last-address': 'last address',
    'summary.valid': 'valid',

    'legend.type-data': 'Data',
    'legend.type-eof': 'EOF',
    'legend.type-es': 'Ext segment',
    'legend.type-ss': 'Start segment',
    'legend.type-04': 'Ext linear',
    'legend.type-sl': 'Start linear',

    'th.index': '#',
    'th.raw': 'Raw line',
    'th.bytes': 'Bytes',
    'th.address': 'Address',
    'th.absolute': 'Absolute',
    'th.type': 'Type',
    'th.data': 'Data',
    'th.checksum': 'Checksum',
    'th.verdict': 'Verdict',

    'record.malformed': 'Malformed',
    'record.type-04': 'Ext linear',
    'record.verdict-ok': 'OK',
    'record.verdict-fail': 'FAILED',
    'record.math-label': 'Checksum math',
    'record.twos-complement': 'two’s complement',
    'record.expected-found': 'expected · found',
    'record.fail-tag': 'FAIL',

    'table.note': 'Addresses in the absolute column are derived from the active extended-address record. Hover a record type for the compact legend; open record 01 for the full 04 explainer.',
    'inspector.title': 'Record inspector',
    'inspector.byte-title': 'Byte inspector',
    'inspector.no-selection': 'No record selected',
    'inspector.choose-record': 'Choose a record to inspect its fields and live checksum.',
    'inspector.open-first': 'Open a file to inspect its records.',
    'inspector.record-n': 'Record',
    'inspector.verified': 'verified',
    'inspector.failed': 'failed',
    'inspector.payload': 'Payload',
    'inspector.bytes': 'bytes',
    'inspector.file-verification': 'File verification',
    'inspector.check-verifies': 'This record verifies',
    'inspector.check-fails': 'This record fails checksum',
    'inspector.check-decoded': 'Fields decoded from the raw line',
    'inspector.check-absolute': 'Absolute address derived from active base',
    'inspector.selected-byte': 'Selected byte',
    'inspector.no-byte': 'No byte selected',
    'inspector.click-byte': 'Click a byte to inspect its address and value.',
    'inspector.selection': 'Selection',
    'inspector.non-printable': 'non-printable',
    'inspector.range-active': 'Range selection is active. Shift-click another byte to extend or reverse it.',
    'inspector.range-hint': 'Shift-click another byte to select an address range.',
    'inspector.basis-title': 'Address basis',
    'inspector.map-title': 'What the map shows',

    'kv.type': 'Type',
    'kv.byte-count': 'Byte count',
    'kv.record-address': 'Record address',
    'kv.absolute': 'Absolute',
    'kv.stored': 'Stored check',
    'kv.expected': 'Expected',
    'kv.address': 'Address',
    'kv.segment': 'Segment',
    'kv.offset': 'Offset',
    'kv.row': 'Row',
    'kv.ascii': 'ASCII',
    'kv.start': 'Start',
    'kv.end': 'End',
    'kv.basis': 'Basis',
    'basis.hex': 'HEX records',
    'basis.bin': 'BIN base',
    'basis.assumed': 'assumed',
    'basis.recorded': 'recorded',

    'map.segment-map': 'Segment map',
    'map.empty': 'No populated bytes yet',
    'map.tip-data': 'Data records; checksums verify.',
    'map.tip-gap': 'No data records in this range. Not the same as an explicit 0xFF fill.',
    'map.note-hex': 'True scale. Addresses come from the records, including the type 04 base. The hatched range is a gap, not erased data.',
    'map.note-bin': 'True scale. The base is this session’s assumption. The hatched range is a gap, not erased data.',
    'map.check-gaps': 'Gaps have no records',
    'map.check-ff': 'Explicit 0xFF is real data',
    'map.check-absolute': 'Addresses are absolute',
    'legend.fbl': 'FBL',
    'legend.app': 'APP',
    'legend.gap': 'Gap',
    'legend.ff': 'Explicit 0xFF',
    'legend.cursor': 'Cursor / selection',

    'skip.gap': 'gap',
    'skip.no-records': '· no data records',

    'hex.title': 'Hex dump · absolute addresses',
    'hex.rows-badge': '16 bytes / row',
    'hex.address': 'Address',
    'hex.ascii': 'ASCII',

    'file.subline-hex': 'Intel HEX — addresses read from extended-address records',
    'file.subline-bin': 'Raw BIN — no address records; base is an assumption',
    'file.rows': 'rows',

    'pop.04.title': 'Record type 04 — Extended Linear Address',
    'pop.04.sub': 'Sets the upper 16 bits for following data records.',
    'pop.04.why-title': 'Why it exists.',
    'pop.04.why': 'A data record only carries a 16-bit address, but flash often lives in a 32-bit address space. Type 04 supplies the missing upper half.',
    'pop.04.derive': 'The next data record at low address 0x0000 becomes absolute address 0x08000000.',
    'pop.04.affects': 'Affects',
    'pop.04.affects-v': 'All following data records',
    'pop.04.until': 'Until',
    'pop.04.until-v': 'Another 02 / 04 or EOF',
    'pop.04.record-data': 'Record data',
    'pop.04.record-data-v': '2 bytes, big-endian base',
    'pop.04.type02': 'Type 02 is the older segment form: the base is shifted 4 bits instead of 16. Both exist because toolchains and legacy programmers still emit them.',
    'pop.04.foot': 'Esc close · click another type chip to explain it',
    'pop.byte-title': 'Byte at',
    'pop.byte-sub': 'Read from the image at its absolute address.',
    'pop.byte-hero': 'hex byte',
    'pop.dec-suffix': 'dec',
    'pop.byte-note': 'The byte value is exact. Its address is only as exact as the current base assumption for a BIN import.',
    'pop.byte-foot': 'Esc close · shift-click to select a range',

    'banner.bin-title': 'BIN carries no address information — the base below is an assumption you set',
    'banner.bin-detail': 'No address records were found. Bitsmith is displaying the bytes at the working base. Check this base against the device memory map before writing.',

    'switch.bin-label': 'BIN state',
    'goto.label': 'Go to address',

    'ops.detail-hint': 'Edit parameters, inspect the before/after effect, then apply to the working copy.',
    'ops.parameters': 'Parameters',
    'ops.absolute-addresses': 'absolute addresses',
    'ops.preview-title': 'Before / after preview',
    'ops.preview-note': 'recomputed from parameters',
    'ops.preview-blocked': 'Preview unavailable',
    'ops.reset-sample': 'Reset sample',
    'ops.review-apply': 'Review and apply',
    'ops.confirm-tail': 'Source files remain untouched.',
    'ops.shared-scale': 'shared linear scale · gaps are unmapped',
    'ops.unmapped': 'unmapped',
    'ops.populated': 'populated',
    'ops.affected-records': 'Affected records',
    'ops.no-record-change': 'No record bytes change.',
    'ops.canonical-note': 'Canonical output comparison; up to four removed and four added lines shown.',
    'ops.affected-bytes': 'Affected bytes',
    'ops.first-12': 'First 12 affected bytes shown.',
    'ops.canonical-counts': 'Canonical HEX records:',
    'ops.gate-blocked': 'Gate blocked',
    'ops.gate-readonly': 'Read-only',
    'ops.gate-ready': 'Preview ready',
    'ops.blocked': 'Blocked',
    'ops.ready': 'Ready',
    'ops.gate-retained': 'Absolute addresses retained. Parameters previewed. Apply requires confirmation.',
    'ops.apply-blocked': 'Apply blocked',
    'ops.digest-computed': 'Digest computed',
    'ops.preview-ready': 'Preview ready',
    'ops.resolve-conflict': 'Resolve the conflict to enable apply',
    'ops.working-copy-only': 'Working copy only',
    'ops.session-note': 'Revision',
    'ops.session-note-2': 'Apply commits this preview; Reset restores the sample. Changes stay in this session.',
    'ops.affected-title': 'Apply gate',
    'ops.scope-title': 'Scope',
    'ops.why-title': 'Why this gate exists',
    'ops.why-copy': 'A conflict is not a warning you can dismiss. It is an overlap between two input images. Change the destination base so their address ranges do not overlap before applying.',
    'ops.session-title': 'Session',
    'ops.confirm-title': 'Apply the preview?',
    'ops.working-copy': 'Working copy',
    'ops.apply-failed': 'Apply failed',
    'crc.computed': 'Computed',
    'crc.live': 'live · no comparison',

    'scope.source': 'Source',
    'scope.format': 'Format',
    'scope.revision': 'Revision',
    'scope.populated': 'Populated bytes',
    'scope.span': 'Span',

    'toast.every-verifies': 'Every record verifies',
    'toast.of': 'of',
    'toast.verified-suffix': 'records verified · recomputed from bytes',
    'toast.records-loaded': 'records · content detected as',
    'toast.unreadable': 'Could not read that file',
    'toast.enter-address': 'Enter a hexadecimal address, for example 0x08008000',
    'toast.no-byte': 'No recorded byte at ',
    'toast.row-no-byte': 'Row at ',

    'learn.back': 'Back to records',
    'learn.on-this-page': 'On this page',
    'learn.sections-label': 'sections',
    'learn.sample-intro-html': 'The sample used throughout is <code>FBL_APP_combined.dat</code>: 8 Intel HEX records, 7 of which verify.',
    'learn.reference': 'Reference',
    'learn.reference-sub': 'The rules behind the view.',
    'learn.intro': 'Nothing in Bitsmith is magic: a record is a text line with a small arithmetic contract, and an address is either in the file or assumed by you. These six sections turn those two facts into arithmetic you can check by hand.',
    'learn.s1': '01 · What a record actually is',
    'learn.s1-intro': 'One Intel HEX line is a complete, self-describing packet. Count tells you how many data bytes follow; address says where they load; type says what the line means; one trailing byte seals the arithmetic.',
    'learn.failing-field-by-field': 'The failing record, field by field',
    'learn.f1-title': 'Count · 04',
    'learn.f1-body': 'Four data bytes follow. A line is not a row of hex; the count defines its shape.',
    'learn.f2-title': 'Address · 8020',
    'learn.f2-body': 'Offset inside the current 64 KiB page. The type 04 record above supplies the upper bits.',
    'learn.f3-title': 'Type · 00',
    'learn.f3-body': '00 is data. 01 ends the file, 02 and 04 extend the address, 03 and 05 are start addresses.',
    'learn.f4-title': 'Data · 48 B1 08 47',
    'learn.f4-body': 'The four payload bytes are preserved exactly; their instruction meaning depends on the target architecture.',
    'learn.f5-title': 'Checksum · 00',
    'learn.f5-body': 'Stored value. This one is wrong: arithmetic says 14. That is the single failing record in the sample.',
    'learn.absolute-note-html': 'The record occupies absolute address <span class="mono">0x08008020</span> because a preceding <span class="mono">:020000040800F2</span> line set the upper 16 bits to <span class="mono">0x0800</span>. Without that line the address would only be <span class="mono">0x8020</span>.',
    'learn.s7-title': 'S7 termination · byte by byte',
    'learn.s7-f1-title': 'Type · S7',
    'learn.s7-f1-body': 'Terminates an S3 stream and carries a 32-bit execution address.',
    'learn.s7-f2-title': 'Count · 05',
    'learn.s7-f2-body': 'Five bytes follow: four address bytes plus one checksum byte.',
    'learn.s7-f3-title': 'Address · 00 00 00 00',
    'learn.s7-f3-body': 'The execution address is 0x00000000; this is metadata, not a data write.',
    'learn.s7-f4-title': 'Data · none',
    'learn.s7-f4-body': 'S7 has no payload; S1, S2 and S3 carry data with 16-, 24- and 32-bit addresses.',
    'learn.s7-f5-title': 'Checksum · FA',
    'learn.s7-f5-body': 'The one\'s complement of count plus address bytes closes this record.',
    'learn.hover-hint-html': 'Hover or focus any byte for its role. The exact input is <span class="mono">S70500000000FA</span>.',
    'learn.s2': '02 · How the checksum is computed',
    'learn.s2-intro': 'Intel HEX uses a two\'s complement checksum. Add every byte after the colon except the checksum itself, keep the low byte, then complement and add one. The result matches the stored byte when the record verifies.',
    'learn.intel-playground': 'Intel HEX record · edit a byte to recompute',
    'learn.srec-playground': 'S-record · one\'s complement',
    'learn.s2-outro': 'Bitsmith recomputes this for every line on every load. A failing checksum does not hide the data: the record stays in the table so you can decide whether to repair or reject it.',
    'learn.s3': '03 · Gaps are not bytes',
    'learn.s3-intro': 'A missing range in the record stream is not the same as a range filled with 0xFF. One is an absence of information; the other is an explicit claim about the device.',
    'learn.gap-title': 'Gap',
    'learn.gap-body-html': 'No record covers the range. The map draws it as an empty striped band, and the tool refuses to pretend it knows what the flash holds there. In the sample, 32,736 bytes from <span class="mono">0x08000020</span> to <span class="mono">0x08007FFF</span> are such a gap.',
    'learn.ff-title': 'Explicit 0xFF',
    'learn.ff-body-html': 'A record actually contains 0xFF bytes. The sample has 16 such bytes at <span class="mono">0x08009FF0</span>. They can be verified, edited, and compared, because they exist in the file.',
    'learn.s3-outro': 'An erase operation turns covered bytes into explicit 0xFF records. A fill operation can also materialise a gap. Both are writes, and both go through the same confirmation gate.',
    'learn.s4': '04 · HEX, S-record, BIN',
    'learn.s4-intro-html': 'The container decides how much the file can prove. Content is sniffed rather than trusted from the extension, because a firmware renamed <span class="mono">.bin</span> is still text records.',
    'learn.tbl.property': 'Property',
    'learn.tbl.address': 'Address in file',
    'learn.tbl.address-hex': 'Yes — 16-bit plus type 02/04 extension',
    'learn.tbl.address-srec': 'Yes — 16, 24 or 32-bit in the record',
    'learn.tbl.address-bin': 'No — nothing but bytes',
    'learn.tbl.checksum': 'Per-line checksum',
    'learn.tbl.checksum-hex': 'Two\'s complement, low byte',
    'learn.tbl.checksum-srec': 'One\'s complement, low byte',
    'learn.tbl.checksum-bin': 'None',
    'learn.tbl.eof': 'End of file',
    'learn.tbl.eof-hex': ':00000001FF',
    'learn.tbl.eof-srec': 'Termination record S7/S8/S9',
    'learn.tbl.eof-bin': 'EOF only',
    'learn.tbl.overhead': 'ASCII overhead',
    'learn.tbl.overhead-text': 'Typically ~3× at short line widths; varies with data length',
    'learn.tbl.overhead-bin': '1× payload; padding may increase size',
    'learn.tbl.use': 'Typical use',
    'learn.tbl.use-hex': 'MCU tools and sparse flash images',
    'learn.tbl.use-srec': 'Automotive / FBL image exchange; .s19 is a common extension',
    'learn.tbl.use-bin': 'Contiguous flash dumps and direct programming',
    'learn.tbl.risk': 'Primary risk',
    'learn.tbl.risk-hex': 'Ignoring extended-address records or overlap',
    'learn.tbl.risk-srec': 'Wrong S1/S2/S3 width or count interpretation',
    'learn.tbl.risk-bin': 'Wrong base, silent gap padding, no per-record checksum',
    'learn.tbl.editable': 'Editable as text',
    'learn.tbl.editable-yes': 'Yes',
    'learn.tbl.editable-no': 'No',
    'learn.tbl.base': 'Base required',
    'learn.tbl.base-no': 'No',
    'learn.tbl.base-yes': 'Yes — an assumption',
    'learn.tbl.session': 'In this session',
    'learn.tbl.session-hex': 'Sample file · recorded',
    'learn.tbl.session-srec': 'Supported · recorded',
    'learn.tbl.session-bin': 'Supported · assumed base',
    'learn.s4-outro-html': 'S-record counts include the address and checksum bytes, unlike Intel HEX where the count covers data only. The checksum is also complemented differently: one\'s complement versus two\'s complement. The live arithmetic on this page lets you verify both by hand.',
    'learn.sources-title': 'Supplied source records · preserved verbatim',
    'learn.s5': '05 · Why a BIN needs a base',
    'learn.s5-intro': 'A raw binary has no idea where it belongs in memory. Bitsmith does not guess quietly: it asks for a base and marks every address downstream of that choice.',
    'learn.s5-example': 'With base 0x08000000, the APP writes at 0x08008000. With base 0x00000000, the same bytes write to 0x00008000.',
    'learn.s5-outro': 'The bytes never move; the interpretation does. That is why the assumed base is shown on every screen and why changing it re-draws the whole map instead of silently shifting.',
    'learn.s5-see-bin': 'See the BIN state',
    'learn.s5-note': 'The sample is Intel HEX, so no base is invented. The BIN state exists to make the assumption visible: it is a working choice, not a property of the file.',
    'learn.s6': '06 · Before you write',
    'learn.s6-intro': 'Reading is cheap; writing is not. These are the checks Bitsmith keeps in front of you, in the order they matter.',
    'learn.s6-1-title': 'Every record verifies, or you know why not',
    'learn.s6-1-body': 'The sample has seven verified records and one failure with its arithmetic shown. A failing record is never silently repaired.',
    'learn.s6-2-title': 'You know which addresses are recorded',
    'learn.s6-2-body': 'Intel HEX and S-record supply addresses. A BIN base is an assumption and stays labelled as one.',
    'learn.s6-3-title': 'Every overlap has an order',
    'learn.s6-3-body': 'Staged operations that claim the same bytes produce a conflict. Choosing a resolution records which intent wins; it never hides the overlap.',
    'learn.s6-4-title': 'Nothing is written until you apply',
    'learn.s6-4-body': 'Operations change a working copy in this session. The source file on disk stays untouched, and the gate stays closed while a conflict is open.',
    'learn.foot.sample': 'Sample · 8 records · 7 verify',
    'learn.foot.hex': 'Intel HEX · recorded addresses',
    'learn.foot.hint': 'Content first · extensions are only a hint',

    'status.content-sniffed': '· content-sniffed',
    'status.esc-suffix': 'close popovers',
    'pop.04.foot-suffix': 'close · click another type chip to explain it',
    'empty.side-open': '<strong>No file open</strong>Open an Intel HEX, S-record, or BIN file to inspect its records. Content sniffing decides the format; the extension is only a hint.',
    'pop.04.why-html': '<strong>Why it exists.</strong> A data record only carries a 16-bit address, but flash often lives in a 32-bit address space. Type 04 supplies the missing upper half.',
    'pop.04.derive-html': '<span class="mono" style="color:var(--text)">0x0800 &lt;&lt; 16 = 0x08000000</span>. The next data record at low address <span class="mono" style="color:var(--text)">0x0000</span> becomes absolute address <span class="mono" style="color:var(--text)">0x08000000</span>.',
    'toast.save-cancelled': 'Save cancelled',
    'toast.saved': 'Saved',
    'toast.save-failed': 'Save failed',
    'toast.open-cancelled': 'No file chosen',
    'toast.loaded-failed': 'Could not decode this file',
    'toc.1': 'Record anatomy',
    'toc.2': 'Checksum arithmetic',
    'toc.3': 'Gaps are not bytes',
    'toc.4': 'HEX, S-record, BIN',
    'toc.5': 'Assumed base',
    'toc.6': 'Before you write',
    'learn.sections-count': '6 sections',
    'learn.s3-intro-html': 'A missing range in the record stream is not the same as a range filled with <span class="mono">0xFF</span>. One is an absence of information; the other is an explicit claim about the device.',
    'learn.tbl.intel-h': 'Intel HEX',
    'learn.tbl.srec-h': 'S19 / S-record',
    'learn.tbl.bin-h': 'Raw BIN',
    'learn.tbl.intel': 'Intel HEX',
    'learn.tbl.srec': 'Motorola S-record',
    'ops.inspect-bytes': 'Inspect bytes',
    'ops.operation-label': 'Operation',
    'ops.staged': 'Staged',
    'ops.conflicts': 'conflicts',
    'status.recorded-hex': 'Recorded addresses · Intel HEX',
    'scope.target': 'Target',
    'scope.working-copy': 'working copy',
    'ops.session-note-static': 'Changes stay in this session. Reset restores the supplied sample.',
    'source.eyebrow-image': 'Source · address basis',
    'pop.byte-foot-suffix': 'close · shift-click to select a range',
    'legend.fbl-data': 'FBL data',
    'legend.app-data': 'APP data',
    'legend.gap-nr': 'Gap / no records',
    'anatomy.intel.colon': 'Start marker',
    'anatomy.intel.count': 'Data byte count',
    'anatomy.intel.addr-high': 'Address high byte',
    'anatomy.intel.addr-low': 'Address low byte',
    'anatomy.intel.type': 'Data record type',
    'anatomy.intel.data-1': 'Payload byte 1',
    'anatomy.intel.data-2': 'Payload byte 2',
    'anatomy.intel.data-3': 'Payload byte 3',
    'anatomy.intel.data-4': 'Payload byte 4',
    'anatomy.intel.checksum': 'Stored checksum',
    'anatomy.srec.type': '32-bit termination record',
    'anatomy.srec.count': 'Address plus checksum count',
    'anatomy.srec.addr-1': 'Execution address byte 1',
    'anatomy.srec.addr-2': 'Execution address byte 2',
    'anatomy.srec.addr-3': 'Execution address byte 3',
    'anatomy.srec.addr-4': 'Execution address byte 4',
    'anatomy.srec.checksum': 'Stored checksum',
    'update.check': 'Check for updates',
    'update.failed': 'Update check failed',
    'theme.to-light': 'Switch to light theme',
    'theme.to-dark': 'Switch to dark theme',
    'lang.switch': 'Language'
  };

  const tables = { en: en, zh: zh };

  let current = 'en';
  try {
    const saved = localStorage.getItem('bitsmith-lang');
    if (saved === 'zh' || saved === 'en') current = saved;
    else if ((navigator.language || '').toLowerCase().indexOf('zh') === 0) current = 'zh';
  } catch (error) { /* default language stands */ }

  function t(key) {
    const table = tables[current];
    return table[key] !== undefined ? table[key] : (tables.en[key] !== undefined ? tables.en[key] : key);
  }

  function apply() {
    document.querySelectorAll('[data-i18n]').forEach(function (node) {
      const value = t(node.dataset.i18n);
      if (!node.querySelector(':scope > *')) node.textContent = value;
      else node.dataset.i18nPending = value; // composed markup keeps its children
    });
    document.querySelectorAll('[data-i18n-html]').forEach(function (node) {
      node.innerHTML = t(node.dataset.i18nHtml);
    });
    document.querySelectorAll('[data-i18n-aria]').forEach(function (node) {
      node.setAttribute('aria-label', t(node.dataset.i18nAria));
    });
    document.documentElement.lang = current === 'zh' ? 'zh-CN' : 'en';
  }

  function setLang(next) {
    current = next === 'zh' ? 'zh' : 'en';
    try { localStorage.setItem('bitsmith-lang', current); } catch (error) { /* keep session choice */ }
    apply();
    window.dispatchEvent(new CustomEvent('bitsmith-lang-changed', { detail: current }));
  }

  /** Injects the language toggle into every page's topbar actions. */
  function injectToggle() {
    const actions = document.querySelector('.topbar-actions');
    if (!actions || document.getElementById('langToggle')) return;
    const button = document.createElement('button');
    button.className = 'btn btn-quiet btn-sm';
    button.id = 'langToggle';
    button.type = 'button';
    button.textContent = current === 'zh' ? 'EN' : '中文';
    button.setAttribute('aria-label', t('lang.switch'));
    button.addEventListener('click', function () {
      setLang(current === 'zh' ? 'en' : 'zh');
      button.textContent = current === 'zh' ? 'EN' : '中文';
    });
    const theme = actions.querySelector('[data-theme-toggle]');
    if (theme) actions.insertBefore(button, theme);
    else actions.appendChild(button);
  }

  /** Open rides the shared topbar button on pages without their own binding. */
  function bindOpenButton() {
    const open = document.getElementById('openFirmware');
    if (!open || open.dataset.bound) return;
    open.dataset.bound = '1';
    open.addEventListener('click', async function () {
      let result = null;
      try {
        result = await window.BitsmithBridge.apiPost('api/workspace/open', { lang: current });
      } catch (error) {
        showToast(t('toast.unreadable'), 'fail');
        return;
      }
      if (result && result.cancelled) showToast(result.phrase || t('toast.open-cancelled'), 'warn');
      else if (result && result.ok) showToast(result.phrase || t('toast.saved'), 'ok');
      else showToast(result && result.error ? result.error : t('toast.unreadable'), result && result.blocked ? 'fail' : 'warn');
    });
  }

  /** Save rides the shared topbar button on every page that has one. */
  function bindSaveButton() {
    const save = document.getElementById('saveFirmware');
    if (!save) return;
    save.addEventListener('click', async function () {
      let result = null;
      try {
        result = await window.BitsmithBridge.apiPost('api/workspace/save', { lang: current });
      } catch (error) {
        showToast(t('toast.save-failed'), 'fail');
        return;
      }
      if (result && result.cancelled) showToast(result.phrase || t('toast.save-cancelled'), 'warn');
      else if (result && result.ok) showToast(result.phrase || t('toast.saved'), 'ok');
      else showToast(result && result.error ? result.error : t('toast.save-failed'), 'fail');
    });
  }

  function showToast(message, tone) {
    const stack = document.getElementById('toastStack');
    if (!stack) return;
    const node = document.createElement('div');
    node.className = 'toast' + (tone === 'fail' ? ' is-fail' : tone === 'warn' ? ' is-warn' : '');
    node.innerHTML =
      '<svg class="od-icon" viewBox="0 0 24 24" aria-hidden="true">' +
        (tone === 'fail' || tone === 'warn'
          ? '<path d="M12 3.5 21 20H3z"></path><path d="M12 9v5M12 17.2v.1"></path>'
          : '<path d="m5 12.5 4.2 4.2L19 7"></path>') +
      '</svg><span></span>';
    node.querySelector('span').textContent = message;
    stack.appendChild(node);
    window.setTimeout(function () {
      node.style.opacity = '0';
      node.style.transform = 'translateY(4px)';
      window.setTimeout(function () { node.remove(); }, 180);
    }, 3400);
  }

  const readyCallbacks = [];
  let booted = false;

  function ready(callback) {
    if (booted) callback();
    else readyCallbacks.push(callback);
  }

  function boot() {
    apply();
    injectToggle();
    bindSaveButton();
    bindOpenButton();
    booted = true;
    readyCallbacks.forEach(function (callback) { callback(); });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }

  window.BitsmithI18n = {
    lang: function () { return current; },
    setLang: setLang,
    t: t,
    apply: apply,
    ready: ready
  };
})();
