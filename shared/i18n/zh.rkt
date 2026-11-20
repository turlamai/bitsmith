#lang racket/base

;; 简体中文字符串。键与 en.rkt 一一对应；键是稳定标识符，文案是产品资产。

(provide strings)

(define strings
  (hasheq
   ;; ---- app ----
   'app-name "Bitsmith"
   'tagline "看懂并驾驭固件镜像"

   ;; ---- format labels ----
   'format-intel "Intel HEX"
   'format-srec "Motorola S-record"
   'format-bin "Raw BIN"
   'format-elf "ELF"

   ;; ---- operation names / descriptions ----
   'op-fill-name "填充"
   'op-fill-desc "把缺失区间实体化"
   'op-pad-name "对齐补齐"
   'op-pad-desc "向后延伸到最后一个分段"
   'op-offset-name "偏移"
   'op-offset-desc "整体搬迁绝对地址"
   'op-crop-name "裁剪"
   'op-crop-desc "保留一个闭区间地址范围"
   'op-merge-name "合并"
   'op-merge-desc "在最宽间隙处切分并重新安放上半部"
   'op-convert-name "转换"
   'op-convert-desc "把输出策略显式化"
   'op-crc-name "CRC"
   'op-crc-desc "从实际工作字节计算"
   'op-badge-edit "编辑"
   'op-badge-read "只读"

   ;; ---- operation field labels ----
   'field-start "起始地址"
   'field-end "结束地址 · 含端点"
   'field-value "填充值"
   'field-alignment "对齐 · 字节"
   'field-delta "有符号偏移量"
   'field-base "目标基址"
   'field-target "目标格式"
   'field-width "S-record 地址宽度"
   'field-line "每行数据字节数"
   'field-preset "预设"
   'field-help "范围含端点。预览以 1 MiB 为限。应用即提交到工作副本。"

   ;; ---- operation note keys (preview copy) ----
   'note-fill "用所选值填充该区间。地址保持绝对；区间内已有字节会被覆盖。"
   'note-pad-aligned "已对齐，未新增字节。"
   'note-pad "向后补齐到对齐边界。补齐是真实数据：保存时与其他字节一样写入。"
   'note-offset "把全部已占用地址按有符号偏移量搬迁；字节内容不变。"
   'note-crop "保留该区间；其余已占用字节全部移除。"
   'note-merge "镜像在最宽间隙处切分：下半部原地保留，上半部搬迁到目标基址。重叠会阻止应用。"
   'note-convert-hex "工作副本保持 Intel HEX。字节内容不变；保存时按规范策略重新生成记录。"
   'note-convert-srec "工作副本保持 S-record 及所选地址宽度。稀疏区间保持稀疏；间隙填充仅用于 BIN。"
   'note-convert-bin "BIN 会用所选填充值实体化所有空洞。地址元数据被显式基址假设取代。"

   ;; ---- CRC preset notes ----
   'crc-note-mpeg2 "汽车项目预设 · xorout 按项目要求取 0xFFFFFFFF。传统 MPEG-2 的 xorout 为 0x00000000。"
   'crc-note-iso-hdlc "与 zlib 兼容 · 输入输出均为反射。"
   'crc-note-xmodem "16 位结果 · 无反射。"
   'crc-note-sum8 "字节求和取模 256；这是加法校验。"
   'crc-read-only "只读 · 不假设任何已存储 CRC，不声称匹配判定。"

   ;; ---- option labels ----
   'option-0x00 "0x00"
   'option-0xFF "0xFF"
   'option-reject "拒绝空洞"
   'option-hex "HEX"
   'option-srec "SREC"
   'option-bin "BIN"
   'option-s1 "S1"
   'option-s2 "S2"
   'option-s3 "S3"
   'option-line-16 "16"
   'option-line-32 "32"

   ;; ---- errors（键为稳定标识符；文案面向用户）----
   'err-address-format "请输入十进制数或以 0x 开头的十六进制数。"
   'err-address-out-of-range "数值超出无符号 32 位地址空间。"
   'err-start-above-end "起始地址必须不大于结束地址。"
   'err-range-too-large "该操作请控制在 1 MiB 以内。"
   'err-value-out-of-range "填充值必须是一个字节（0x00-0xFF）。"
   'err-alignment-invalid "对齐值必须是 1 到 1048576 之间的 2 的幂。"
   'err-empty-image "尚未加载镜像。"
   'err-crop-empty "该裁剪会得到空镜像。请选择一个包含数据的范围。"
   'err-merge-two-segments "合并需要镜像中存在可切分的间隙。请先用裁剪和偏移整形输入。"
   'err-merge-overlap "重叠冲突：搬迁后的部分覆盖了已有字节。请设置不重叠的目标基址。"
   'err-relocation-out-of-range "搬迁会超出无符号 32 位地址空间。"
   'err-width-loss "该 S-record 宽度无法编码最高已占用地址。32 位绝对地址请使用 S3；不做隐式截断或搬移。"
   'err-bin-base-above-start "BIN 基址必须不大于首个已占用地址。"
   'err-bin-too-large "BIN 输出超出 1 MiB 工作上限。"
   'err-unknown-op "未知操作。"
   'err-unknown-preset "未知 CRC 预设。"
   'err-crc-unmapped-at "所示地址存在未映射字节。请选择显式填充策略或收窄范围。"
   'err-not-elf "该文件不是 ELF 镜像。"
   'err-elf-truncated "ELF 头被截断；文件可能已损坏。"
   'err-elf-unsupported-class "不支持的 ELF 类别；只读摘要覆盖 ELF32 与 ELF64。"
   'err-elf-unsupported-data "不支持的 ELF 字节序；只读摘要覆盖大端与小端。"
   'err-elf-no-sections "该 ELF 没有节表；只读摘要需要节表。"
   'err-file-too-large "文件超出本预览版 4 MiB 的打开上限。"
   'err-unreadable "无法读取该文件。"
   'err-no-valid-records "未找到有效记录。请确认文件是 Intel HEX 或 Motorola S-record 后重试。"
   'err-revision-conflict "预览之后工作副本已变化。请重新预览后再应用。"

   ;; ---- workspace phrases ----
   'phrase-sample-restored "样例镜像已恢复 · 校验和已重算"
   'phrase-loaded "已加载 · 内容已识别"
   'phrase-saved "已保存"
   'phrase-save-cancelled "已取消保存"
   'phrase-open-cancelled "未选择文件"
   'phrase-file-closed "文件已关闭 · 工作区已清空"
   'phrase-conversion-applied "格式已切换 · 字节未变"
   'phrase-bin-materialised "空洞已按所选填充值实体化"
   'phrase-applied "已应用到工作副本 · 版本"

   ;; ---- file dialog ----
   'dialog-open-title "打开固件镜像"
   'dialog-save-title "保存固件镜像"
   'filter-hex "Intel HEX 文件"
   'filter-srec "S-record 文件"
   'filter-bin "二进制文件"
   'filter-all "全部文件"

   ;; ---- record-view phrases（引擎侧）----
   'phrase-verify-copy "每次加载都从字节重新计算校验和。"
   'phrase-live-verify "实时校验逐条从字节重算。界面中不存在任何硬编码判定。"
   'phrase-checksum-mismatch "校验和不一致。"
   'phrase-checksum-mismatch-detail "字节求和得到所示值；二进制补码给出期望值，但该行存储的是另一个字节。该行保持可见，由你决定修复还是拒绝。"
   'phrase-checksum-ok "校验和通过。存储的校验字节与计算值一致。"
   'phrase-base-record "该记录设置基址。它不写任何 flash 字节；其载荷成为后续记录的高位地址。"

   ;; ---- image-view phrases ----
   'phrase-bin-banner "BIN 不携带地址信息——下方基址是你设定的假设"
   'phrase-bin-banner-detail "未找到地址记录。Bitsmith 按当前工作基址显示字节。写入前请对照设备内存映射核对该基址。"
   'phrase-hex-basis-hex "所示地址来自文件的记录本身，无需基址假设。"
   'phrase-hex-basis-bin "BIN 没有地址记录。本次会话把首字节视为工作基址；所有地址继承该假设。"

   ;; ---- learn view（引擎验证的算术）----
   'learn-intel-step-1 "字节求和"
   'learn-intel-step-1-note "计数、地址与数据；Intel HEX 还包含类型。"
   'learn-intel-step-2 "取低字节"
   'learn-intel-step-2-note "丢弃八位以上的进位。"
   'learn-intel-step-3 "二进制补码"
   'learn-intel-step-3-note "100 减低字节，掩码到八位。"
   'learn-intel-step-4 "比对"
   'learn-intel-step-4-note "存储值与计算值。"
   'learn-srec-step-3 "反码"
   'learn-srec-step-3-note "FF 减低字节，掩码到八位。"
   'learn-input-error "请输入冒号加完整的十六进制字节对（计数、地址、类型、数据、校验和）。"
   'learn-count-mismatch "计数不一致：计数声明的是所示数据字节数，但该行包含的数量不同。"
   'learn-pass "通过 · 校验和从当前输入计算得出。"
   'learn-fail "不通过 · 存储值与计算值不同。输入保持原样；不做任何修复。"

   ;; ---- update check ----
   'update-check "检查更新"
   'update-available "有新版本可用：v~a"
   'update-uptodate "已是最新版本"

   ;; ---- save format chooser ----
   'save-format "格式"
   'save-format-current "当前格式"))
