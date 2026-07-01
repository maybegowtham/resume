#!/bin/bash
set -e

# --- Config ---
TEX_FILE="resume.tex"
REQUIRED_PKGS=("texlive-latex-base" "texlive-fonts-recommended" "texlive-latex-extra")

# --- Check commit message argument ---
if [ -z "$1" ]; then
    echo "Usage: $0 \"commit message\""
    exit 1
fi

# --- Check and install missing LaTeX packages ---
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Installing missing packages: ${MISSING_PKGS[*]}"
    sudo apt-get update
    sudo apt-get install -y "${MISSING_PKGS[@]}"
else
    echo "All required LaTeX packages already installed."
fi

# --- Compile resume (output junk files to a temp dir, keep only the PDF) ---
echo "Compiling $TEX_FILE..."
BUILD_DIR=$(mktemp -d)

if ! pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$BUILD_DIR" "$TEX_FILE" > "$BUILD_DIR/build.log" 2>&1; then
    echo "pdflatex failed to compile $TEX_FILE. Aborting commit."
    echo "---- Last 20 lines of log ----"
    tail -n 20 "$BUILD_DIR/build.log"
    rm -rf "$BUILD_DIR"
    exit 1
fi

PDF_NAME="${TEX_FILE%.tex}.pdf"
cp "$BUILD_DIR/$PDF_NAME" ./"$PDF_NAME"
rm -rf "$BUILD_DIR"

echo "Compiled $PDF_NAME successfully."

# --- Commit ---
git add .
git commit -m "$1"
git push

echo "Done."
