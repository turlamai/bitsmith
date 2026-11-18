#lang racket/base
;; 简体中文字符串。键与 en.rkt 一一对应。
(provide strings)

(define strings
  (hasheq 'app-name "Binlet"
          'tagline "看懂并驾驭固件镜像"))
