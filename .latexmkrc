#!/usr/bin/env perl

# LaTeX処理系の設定
$latex = 'uplatex -synctex=1 -halt-on-error -interaction=nonstopmode';
$pdflatex = 'pdflatex -synctex=1 -halt-on-error -interaction=nonstopmode';
$lualatex = 'lualatex -synctex=1 -halt-on-error -interaction=nonstopmode';
$xelatex = 'xelatex -synctex=1 -halt-on-error -interaction=nonstopmode';

# BibTeX処理系の設定
$bibtex = 'upbibtex %O %B';
$biber = 'biber %O %B';

# インデックス処理系の設定
$makeindex = 'mendex -r -c -s jind.ist';

# DVI -> PDF変換の設定
$dvipdf = 'dvipdfmx -o %D %O %S';

# PDF生成方法の設定（日本語の場合は通常4を使用）
$pdf_mode = 4;

# 出力ディレクトリの設定
$out_dir = 'build';

# # 強制コンパイルを有効化
# $force_mode = 1;

# 自動プレビューを無効化
$preview_continuous_mode = 0;
$preview_mode = 0;
