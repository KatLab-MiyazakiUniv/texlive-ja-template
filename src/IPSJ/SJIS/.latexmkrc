#!/usr/bin/env perl

# pLaTeX + dvipdfmx 用設定（UTF-8専用）

# LaTeX 処理系の設定（uplatex使用）
$latex = 'uplatex %O -synctex=1 -interaction=nonstopmode %S';
$pdflatex = 'pdflatex %O -synctex=1 -interaction=nonstopmode %S';

# DVI -> PDF変換の設定（dvipdfmx使用）
$dvipdf = 'dvipdfmx %O -o %D %S';

$dvips = 'dvips %O -z -f %S | convbkmk -u > %D';
$ps2pdf = 'ps2pdf %O %S %D';

# PDF 生成方法の設定
# 3: LaTeX -> DVI -> PDF (uplatex + dvipdfmx)
$pdf_mode = 3;
