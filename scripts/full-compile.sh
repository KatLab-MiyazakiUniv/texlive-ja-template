#!/bin/bash
set -euo pipefail

# Full compilation script for LaTeX + BibTeX
# Usage: ./full-compile.sh <tex-file-without-extension>
#
# This script performs a complete LaTeX compilation including:
# - Multiple LaTeX passes for cross-references
# - pBibTeX for bibliography processing
# - DVI to PDF conversion

# Logging functions
log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Compilation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup_on_exit EXIT

if [[ $# -lt 1 || $# -gt 2 ]]; then
    log_error "Invalid number of arguments"
    echo "Usage: $0 <tex-file-without-extension> [encoding]"
    echo "Example: $0 jsample UTF8"
    echo "Example: $0 jsample SJIS"
    echo "Encoding options: UTF8, SJIS (default: UTF8)"
    exit 1
fi

TEX_BASE="$1"
ENCODING="${2:-UTF8}"  # デフォルトはUTF8
WORKSPACE="/workspace"

# エンコーディング別の設定
case "$ENCODING" in
    "UTF8")
        SOURCE_DIR="src/IPSJ/UTF8"
        COMPILER="platex"
        LANG_ENV="LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8"
        ;;
    "SJIS")
        SOURCE_DIR="src/IPSJ/SJIS"
        COMPILER="platex"
        LANG_ENV="LANG=ja_JP.SJIS LC_ALL=ja_JP.SJIS"
        ;;
    *)
        log_error "Unsupported encoding: $ENCODING"
        echo "Supported encodings: UTF8, SJIS"
        exit 1
        ;;
esac

# Check if we're inside Docker
if [[ ! -f /.dockerenv ]]; then
    log_error "This script must be run inside the Docker container"
    exit 1
fi

cd "$WORKSPACE"

log_info "=== Full compilation of $TEX_BASE (encoding: $ENCODING) ==="

# Step 1: Clean all intermediate files
log_info "Step 1: Cleaning intermediate files..."
rm -f "build/${TEX_BASE}."* "${SOURCE_DIR}/${TEX_BASE}.aux" "${SOURCE_DIR}/${TEX_BASE}.bbl" 2>/dev/null || true

# Step 2: First LaTeX compilation
log_info "Step 2: First LaTeX compilation..."
cd "$SOURCE_DIR"
if ! eval "$LANG_ENV $COMPILER -output-directory=../../../build -interaction=nonstopmode '${TEX_BASE}.tex'" > /dev/null 2>&1; then
    log_warn "First LaTeX compilation had warnings/errors (continuing)"
fi

# Check for cross-references and citations
check_references() {
    local aux_file="../../../build/${TEX_BASE}.aux"
    local log_file="../../../build/${TEX_BASE}.log"

    # Check for undefined references
    if [[ -f "$log_file" ]] && grep -q "LaTeX Warning.*undefined" "$log_file"; then
        return 1  # References still undefined
    fi

    # Check for citation warnings
    if [[ -f "$log_file" ]] && grep -q "LaTeX Warning.*Citation" "$log_file"; then
        return 1  # Citations still undefined
    fi

    # Check for "Rerun to get cross-references right"
    if [[ -f "$log_file" ]] && grep -q "Rerun to get cross-references right" "$log_file"; then
        return 1  # Need to rerun
    fi

    return 0  # All references resolved
}

# Step 3: Check if bibliography is needed and handle multiple compilations
# Wait a moment for aux file to be fully written
sleep 1
if grep -q "\\\\bibdata\\|\\\\citation" "../../../build/${TEX_BASE}.aux" 2>/dev/null; then
    log_info "Step 3: Running pBibTeX..."
    cd ../../../build

    # Copy necessary files
    cp "../${SOURCE_DIR}"/*.bib . 2>/dev/null || log_warn "No .bib files found"
    cp "../${SOURCE_DIR}"/*.bst . 2>/dev/null || log_warn "No .bst files found"

    # Run pBibTeX with verbose output for debugging
    if pbibtex "$TEX_BASE"; then
        log_info "pBibTeX completed successfully"
        # Copy .bbl file back to source directory
        cp "${TEX_BASE}.bbl" "../${SOURCE_DIR}/" 2>/dev/null || log_warn "Failed to copy .bbl file"
    else
        log_warn "pBibTeX failed, continuing without bibliography"
    fi

    cd "$WORKSPACE/$SOURCE_DIR"
else
    log_info "No bibliography found, skipping pBibTeX"
    cd "$WORKSPACE/$SOURCE_DIR"
fi

# Step 4-N: Compile until all references are resolved
log_info "Step 4: Compiling until all references are resolved..."
compile_count=2
max_compiles=10

while [[ $compile_count -le $max_compiles ]]; do
    log_info "LaTeX compilation #${compile_count}..."
    if ! eval "$LANG_ENV $COMPILER -output-directory=../../../build -interaction=nonstopmode '${TEX_BASE}.tex'" > /dev/null 2>&1; then
        log_warn "LaTeX compilation #${compile_count} had warnings/errors (continuing)"
    fi

    # Check if references are resolved
    if check_references; then
        log_info "All references resolved after ${compile_count} compilations"
        break
    elif [[ $compile_count -eq $max_compiles ]]; then
        log_warn "Reached maximum compilations ($max_compiles). Some references may still be unresolved."
        break
    else
        log_info "References still unresolved, continuing..."
        ((compile_count++))
    fi
done

# Step 5: Copy images to build directory
log_info "Step 5: Copying images to build directory..."
cd "$WORKSPACE/build"
if [[ -d "../${SOURCE_DIR}/images" ]]; then
    cp -r "../${SOURCE_DIR}/images" . 2>/dev/null || log_warn "Failed to copy images directory"
    log_info "Images copied successfully"
else
    log_warn "No images directory found"
fi

# Step 6: Generate PDF
log_info "Step 6: Generating PDF..."
if [[ -f "${TEX_BASE}.dvi" ]]; then
    if dvipdfmx "${TEX_BASE}.dvi" 2>/dev/null || [[ -f "${TEX_BASE}.pdf" ]]; then
        log_info "PDF generation successful"
        
        # Copy PDF to output directory
        PDF_OUTPUT_DIR="../pdf/IPSJ/${ENCODING}"
        mkdir -p "$PDF_OUTPUT_DIR"
        if cp "${TEX_BASE}.pdf" "$PDF_OUTPUT_DIR/" 2>/dev/null; then
            log_info "=== Compilation completed successfully ==="
            log_info "PDF: pdf/IPSJ/${ENCODING}/${TEX_BASE}.pdf"
            ls -la "$PDF_OUTPUT_DIR/${TEX_BASE}.pdf" 2>/dev/null || log_warn "PDF file not found in final location"
        else
            log_error "Failed to copy PDF to output directory"
            exit 1
        fi
    else
        log_error "DVI to PDF conversion failed"
        exit 1
    fi
else
    log_error "DVI file not generated"
    exit 1
fi
