#!/usr/bin/env perl

# Shift JIS 専用設定

# LaTeX 処理系の設定（SJIS用）
$latex = 'platex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$pdflatex = 'pdflatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$lualatex = 'lualatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$xelatex = 'xelatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';

# BibTeX 処理系の設定
$bibtex = 'pbibtex %O %B';
$biber = 'biber %O --bblencoding=utf8 -u -U --output_safechars %B';

# インデックス処理系の設定
$makeindex = 'mendex -r -c -s jind.ist';

# DVI -> PDF変換の設定
$dvipdf = 'dvipdfmx -o %D %O %S';

# PDF 生成方法の設定（platex + dvipdfmx）
$pdf_mode = 3;

# 出力ディレクトリの設定
$out_dir = '../../build';

# 自動プレビューを無効化
$preview_continuous_mode = 0;
$preview_mode = 0;

# 最大繰り返し数を設定
$max_repeat = 5;

# エラー時の動作
$failure_cmd = '';

# 日本語対応（SJIS）
$ENV{'LANG'} = 'ja_JP.SJIS';
$ENV{'LC_ALL'} = 'ja_JP.SJIS';

# フォント警告を許可（警告でもコンパイルを続行）
$warnings_as_errors = 0;
$force_mode = 1;  # フォントエラーでも強制的に続行