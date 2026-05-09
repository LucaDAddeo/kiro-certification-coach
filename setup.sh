#!/usr/bin/env bash
# =============================================================================
# Certification Coach Agent - Knowledge Base Setup
# =============================================================================
# This script:
#   1. Verifies the Kiro CLI Knowledge feature is enabled
#   2. Validates all required source files exist
#   3. Creates symlinks to exam materials
#   4. Initializes the Knowledge Base with exam content
# =============================================================================

set -euo pipefail

WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_ID="aip-c01"
CERT_DIR="$WORKSPACE_DIR/certifications/$CERT_ID"
QUESTIONS_DIR="$CERT_DIR/questions"

# Source locations (existing files on the USB drive)
EXAM_GUIDE_SOURCE="/Volumes/MAC-USB/AWS/AIP-C01/AIP-C01  - Exam Guide.pdf"
QUIZMAKER_DIR="/Volumes/MAC-USB/AWS/AIP-C01/QuizMaker/processed"

# Expected question files
QUESTION_FILES=(
  "AIP-C01_Set_1_Processato.md"
  "AIP-C01_Set_2_Processato.md"
  "AIP-C01_Bonus_Set_3_Processato.md"
)

# =============================================================================
# Helpers
# =============================================================================

info()  { echo "ℹ️  $*"; }
ok()    { echo "✅ $*"; }
warn()  { echo "⚠️  $*" >&2; }
err()   { echo "❌ $*" >&2; }

# =============================================================================
# Banner
# =============================================================================
echo ""
echo "🎓 Certification Coach Agent — Setup"
echo "======================================"
echo "Workspace: $WORKSPACE_DIR"
echo "Certification: $CERT_ID"
echo ""

# =============================================================================
# Phase 1: Validate Kiro CLI Knowledge feature is enabled
# =============================================================================
echo "=== Phase 1: Validating Kiro CLI Knowledge feature ==="

if ! command -v kiro-cli &>/dev/null; then
  err "Kiro CLI is not installed or not in PATH."
  echo ""
  echo "Please install Kiro CLI first:"
  echo "  https://kiro.dev/cli/"
  exit 1
fi
ok "Kiro CLI is installed"

# Check if Knowledge feature is enabled (best effort — exact settings command may vary)
KNOWLEDGE_ENABLED=false
if kiro-cli settings chat.enableKnowledge 2>/dev/null | grep -qiE "true|enabled"; then
  KNOWLEDGE_ENABLED=true
fi

if [[ "$KNOWLEDGE_ENABLED" != "true" ]]; then
  warn "Knowledge feature may not be enabled."
  echo ""
  echo "To enable it (experimental feature), run:"
  echo "  kiro-cli settings chat.enableKnowledge true"
  echo ""
  read -r -p "Continue anyway? (y/N) " CONT
  if [[ ! "$CONT" =~ ^[yY]$ ]]; then
    info "Exiting. Enable the feature and re-run this script."
    exit 1
  fi
else
  ok "Knowledge feature is enabled"
fi

# =============================================================================
# Phase 2: Validate source files exist
# =============================================================================
echo ""
echo "=== Phase 2: Validating source files ==="

MISSING_FILES=()

if [[ ! -f "$EXAM_GUIDE_SOURCE" ]]; then
  MISSING_FILES+=("Exam guide: $EXAM_GUIDE_SOURCE")
fi

if [[ ! -d "$QUIZMAKER_DIR" ]]; then
  MISSING_FILES+=("QuizMaker directory: $QUIZMAKER_DIR")
else
  for qf in "${QUESTION_FILES[@]}"; do
    if [[ ! -f "$QUIZMAKER_DIR/$qf" ]]; then
      MISSING_FILES+=("Question file: $QUIZMAKER_DIR/$qf")
    fi
  done
fi

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
  err "The following required source files are missing:"
  for mf in "${MISSING_FILES[@]}"; do
    echo "   - $mf" >&2
  done
  echo ""
  echo "Ensure the USB drive is mounted and all AIP-C01 materials are present." >&2
  exit 1
fi
ok "Exam guide found"
ok "All ${#QUESTION_FILES[@]} question file(s) found"

# =============================================================================
# Phase 3: Create symlinks in the workspace
# =============================================================================
echo ""
echo "=== Phase 3: Creating symlinks to exam materials ==="

# Ensure target directories exist
mkdir -p "$QUESTIONS_DIR"

# Exam guide symlink
EXAM_GUIDE_LINK="$CERT_DIR/exam-guide.pdf"
if [[ -L "$EXAM_GUIDE_LINK" ]] || [[ -f "$EXAM_GUIDE_LINK" ]]; then
  rm -f "$EXAM_GUIDE_LINK"
fi
ln -s "$EXAM_GUIDE_SOURCE" "$EXAM_GUIDE_LINK"
ok "Linked exam guide → $EXAM_GUIDE_LINK"

# Question file symlinks
for qf in "${QUESTION_FILES[@]}"; do
  LINK="$QUESTIONS_DIR/$qf"
  if [[ -L "$LINK" ]] || [[ -f "$LINK" ]]; then
    rm -f "$LINK"
  fi
  ln -s "$QUIZMAKER_DIR/$qf" "$LINK"
  ok "Linked $qf"
done

# =============================================================================
# Phase 4: Initialize Knowledge Base
# =============================================================================
echo ""
echo "=== Phase 4: Initializing Knowledge Base ==="

info "Adding exam guide to Knowledge Base..."
if ! kiro-cli /knowledge add --name "${CERT_ID}-exam-guide" --path "$EXAM_GUIDE_LINK" 2>&1; then
  warn "Failed to add exam guide. You can add it manually later with:"
  echo "  kiro-cli /knowledge add --name \"${CERT_ID}-exam-guide\" --path \"$EXAM_GUIDE_LINK\""
else
  ok "Exam guide added to KB"
fi

info "Adding processed questions directory to Knowledge Base..."
if ! kiro-cli /knowledge add --name "${CERT_ID}-questions" --path "$QUESTIONS_DIR" 2>&1; then
  warn "Failed to add questions directory. You can add it manually later with:"
  echo "  kiro-cli /knowledge add --name \"${CERT_ID}-questions\" --path \"$QUESTIONS_DIR\""
else
  ok "Questions directory added to KB"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "======================================"
ok "Setup complete!"
echo "======================================"
echo ""
echo "🚀 To start the agent, run:"
echo "   kiro-cli --agent $WORKSPACE_DIR/agent.json"
echo ""
echo "Or, if using Kiro IDE, point the custom agent to:"
echo "   $WORKSPACE_DIR/agent.json"
echo ""
echo "Useful commands inside the agent:"
echo "   /quiz [dominio] [difficoltà] [numero]"
echo "   /score"
echo "   /weak"
echo "   /explain [argomento]"
echo ""
