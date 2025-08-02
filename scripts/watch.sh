#!/usr/bin/env bash
set -uo pipefail

cd /workspace || {
  echo "[ERROR] Cannot change directory to /workspace" >&2
  exit 1
}

tex_compile() {
  local tex="$1"
  echo "[INFO] Compiling: $tex"

  if [[ "$tex" =~ UTF8/ ]]; then
    echo "[INFO] UTF-8 encoding detected: $tex"

    # ディレクトリを適切に設定
    if [[ "$tex" =~ IPSJ/UTF8/ ]]; then
      cd src/IPSJ/UTF8
      tex_file="$(basename "$tex")"
    else
      cd src/UTF8
      tex_file="$(basename "$tex")"
    fi

    # 古いファイルをクリーンアップ（buildディレクトリから）
    rm -f "../../../build/$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}

    # TEXINPUTSパスをディレクトリに応じて設定
    if [[ "$tex" =~ IPSJ/ ]]; then
      texinputs_path=".:./../../../src//:"
      build_path="../../../build/$(basename "$tex" .tex).pdf"
      output_dir="../../../build"
    else
      texinputs_path=.:../../src//:
      build_path="../../build/$(basename "$tex" .tex).pdf"
      output_dir="../../build"
    fi

    # 中間ファイルをbuildディレクトリに出力するためのオプション
    TEXINPUTS="$texinputs_path" LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -output-directory="$output_dir" -interaction=nonstopmode "$tex_file" || true
    dvi_file="$output_dir/$(basename "$tex" .tex).dvi"
    
    # DVIファイルが生成されていれば成功とみなす（警告があっても）
    if [[ -f "$dvi_file" ]]; then
      pdf_output="$output_dir/$(basename "$tex" .tex).pdf"
      if dvipdfmx -o "$pdf_output" "$dvi_file" 2>/dev/null; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex - DVI file not generated"
    fi

    cd - >/dev/null
  elif [[ "$tex" =~ SJIS/ ]]; then
    echo "[INFO] SJIS encoding detected: $tex"

    # ディレクトリを適切に設定
    if [[ "$tex" =~ IPSJ/SJIS/ ]]; then
      cd src/IPSJ/SJIS
      tex_file="$(basename "$tex")"
    else
      cd src/SJIS
      tex_file="$(basename "$tex")"
    fi

    # 古いファイルをクリーンアップ（buildディレクトリから）
    rm -f "../../../build/$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}

    # TEXINPUTSパスをディレクトリに応じて設定
    if [[ "$tex" =~ IPSJ/ ]]; then
      texinputs_path=".:./../../../src//:"
      build_path="../../../build/$(basename "$tex" .tex).pdf"
      output_dir="../../../build"
    else
      texinputs_path=.:../../src//:
      build_path="../../build/$(basename "$tex" .tex).pdf"
      output_dir="../../build"
    fi

    # 中間ファイルをbuildディレクトリに出力するためのオプション
    TEXINPUTS="$texinputs_path" LANG=ja_JP.SJIS LC_ALL=ja_JP.SJIS platex -output-directory="$output_dir" -interaction=nonstopmode "$tex_file" || true
    dvi_file="$output_dir/$(basename "$tex" .tex).dvi"
    
    # DVIファイルが生成されていれば成功とみなす（警告があっても）
    if [[ -f "$dvi_file" ]]; then
      pdf_output="$output_dir/$(basename "$tex" .tex).pdf"
      if dvipdfmx -o "$pdf_output" "$dvi_file" 2>/dev/null; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex - DVI file not generated"
    fi
    
    cd - >/dev/null
  else
    echo "[INFO] Standard encoding: $tex"
    # 古いファイルをクリーンアップ（buildディレクトリから）
    rm -f "build/$(basename "$tex" .tex)".{aux,dvi,log,out,toc,synctex.gz}
    TEXINPUTS=./src//: LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 uplatex -output-directory=build -interaction=nonstopmode "$tex" || true
    dvi_file="build/$(basename "$tex" .tex).dvi"
    
    # DVIファイルが生成されていれば成功とみなす（警告があっても）
    if [[ -f "$dvi_file" ]]; then
      if dvipdfmx -o "build/$(basename "$tex" .tex).pdf" "$dvi_file" 2>/dev/null; then
        echo "[INFO] LaTeX compilation successful for $tex"
      else
        echo "[WARN] DVI to PDF conversion failed for $tex"
      fi
    else
      echo "[WARN] LaTeX compilation failed for $tex - DVI file not generated"
    fi
  fi

  # サブディレクトリ構造を維持してPDFをコピー
  local rel_path="${tex#src/}"
  local pdf_dir="pdf/$(dirname "$rel_path")"
  mkdir -p "$pdf_dir"
  local pdf_name="${rel_path%.tex}.pdf"
  local build_pdf="build/$(basename "$tex" .tex).pdf"
  
  # PDFが存在するかチェックしてからコピー
  if [[ -f "$build_pdf" ]]; then
    if cp "$build_pdf" "pdf/$pdf_name"; then
      echo "[INFO] PDF created: pdf/$pdf_name"
    else
      echo "[WARN] Failed to copy PDF for $tex"
    fi
  else
    echo "[WARN] Build PDF not found: $build_pdf"
  fi
}

compile_single() {
  local tex="$1"
  tex_compile "$tex"
  echo "[INFO] Single file compilation finished for: $tex"
}

# シグナルハンドリング
trap 'echo "[INFO] Watch stopped"; exit 0' SIGINT SIGTERM

echo "[INFO] Using polling method for Docker mount compatibility"

# ポーリング監視
declare -A file_times

# 初期ファイル時刻を記録
while IFS= read -r -d '' tex; do
  file_times["$tex"]=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
  echo "[INFO] Tracking: $tex"
done < <(find src -name "*.tex" -type f -print0)

while true; do
  while IFS= read -r -d '' tex; do
    current=$(stat -c %Y "$tex" 2>/dev/null || stat -f %m "$tex")
    if [[ "${file_times[$tex]:-}" != "$current" ]]; then
      file_times["$tex"]=$current
      echo "[INFO] Change detected in: $tex"
      compile_single "$tex"
    fi
  done < <(find src -name "*.tex" -type f -print0)
  sleep 1
done
