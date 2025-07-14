#!/usr/bin/env perl

# LaTeX 処理系の設定
$latex = 'uplatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$pdflatex = 'pdflatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$lualatex = 'lualatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';
$xelatex = 'xelatex -synctex=1 -halt-on-error -interaction=nonstopmode -file-line-error';

# BibTeX 処理系の設定
$bibtex = 'upbibtex %O %B';
$biber = 'biber %O --bblencoding=utf8 -u -U --output_safechars %B';

# インデックス処理系の設定
$makeindex = 'mendex -r -c -s jind.ist';

# DVI -> PDF変換の設定
$dvipdf = 'dvipdfmx -o %D %O %S';

# PDF 生成方法の設定（uplatex + dvipdfmx）
$pdf_mode = 3;

# 出力ディレクトリの設定
$out_dir = 'build';

# PDF の出力先を指定
ensure_path('pdf');
$pdf_dir = 'pdf';
$pdf_update_method = 2;  # PDFを指定ディレクトリに自動コピー
$pdf_update_command = 'cp %D pdf/%R.pdf';

# 自動プレビューを無効化
$preview_continuous_mode = 0;
$preview_mode = 0;

# 最大繰り返し数を設定
$max_repeat = 5;

# エラー時の動作
$failure_cmd = '';

# 日本語対応の強化
$ENV{'LANG'} = 'ja_JP.UTF-8';
$ENV{'LC_ALL'} = 'ja_JP.UTF-8';
