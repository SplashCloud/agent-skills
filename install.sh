#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SKILL_FILTER=""
SCOPE="global"
AGENT=""
PROJECT_DIR="$PWD"
FORCE=0

usage() {
  cat <<'EOF'
用法:
  ./install.sh --agent <codex|claude|omp> [选项]

选项:
  --skill NAME        只安装指定 skill；省略时安装全部 skill
  --agent NAME        目标 coding agent（必填）
  --scope SCOPE       project 或 global，默认 global
  --project-dir DIR   project scope 的目标项目目录，默认当前目录
  --force             覆盖已有的 skill；默认跳过已有 skill
  -h, --help          显示帮助

示例:
  ./install.sh --agent codex --scope project
  ./install.sh --skill code-review --agent codex --scope project
  ./install.sh --agent claude --scope global
  ./install.sh --skill tldr --agent omp --scope project --project-dir ../my-app
EOF
}

fail() { printf '错误: %s\n' "$1" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --skill)
      (($# >= 2)) || fail "--skill 需要一个值"
      SKILL_FILTER="$2"; shift 2 ;;
    --agent)
      (($# >= 2)) || fail "--agent 需要一个值"
      AGENT="$2"; shift 2 ;;
    --scope)
      (($# >= 2)) || fail "--scope 需要一个值"
      SCOPE="$2"; shift 2 ;;
    --project-dir)
      (($# >= 2)) || fail "--project-dir 需要一个值"
      PROJECT_DIR="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "未知参数: $1" ;;
  esac
done

[[ -n "$AGENT" ]] || { usage >&2; fail "必须指定 --agent"; }
[[ -z "$SKILL_FILTER" || "$SKILL_FILTER" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "--skill 只能包含小写字母、数字和连字符"
[[ "$AGENT" == "codex" || "$AGENT" == "claude" || "$AGENT" == "omp" ]] || fail "--agent 只能是 codex、claude 或 omp"
[[ "$SCOPE" == "project" || "$SCOPE" == "global" ]] || fail "--scope 只能是 project 或 global"

case "$AGENT:$SCOPE" in
  codex:project|omp:project) TARGET_ROOT="$PROJECT_DIR/.agents/skills" ;;
  codex:global) TARGET_ROOT="${CODEX_HOME:-$HOME/.codex}/skills" ;;
  omp:global) TARGET_ROOT="$HOME/.agents/skills" ;;
  claude:project) TARGET_ROOT="$PROJECT_DIR/.claude/skills" ;;
  claude:global) TARGET_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" ;;
esac

if [[ -n "$SKILL_FILTER" ]]; then
  SKILLS=("$SKILL_FILTER")
else
  mapfile -t SKILLS < <(find "$ROOT_DIR/original-skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  ((${#SKILLS[@]} > 0)) || fail "没有找到任何 skill"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TARGET_ROOT"

installed=0
skipped=0
for skill in "${SKILLS[@]}"; do
  SOURCE_DIR="$ROOT_DIR/original-skills/$skill"
  TARGET_DIR="$TARGET_ROOT/$skill"

  [[ -d "$SOURCE_DIR" ]] || fail "找不到 skill: $skill"
  [[ -f "$SOURCE_DIR/description.txt" ]] || fail "找不到 $skill 的 description.txt"
  [[ -s "$SOURCE_DIR/description.txt" ]] || fail "$skill 的 description.txt 不能为空"
  [[ -f "$SOURCE_DIR/instructions.md" ]] || fail "找不到 $skill 的 instructions.md"
  [[ -f "$SOURCE_DIR/examples.md" || -f "$SOURCE_DIR/README.md" ]] || fail "找不到 $skill 的示例或 README"
  DESCRIPTION="$(< "$SOURCE_DIR/description.txt")"

  if [[ -e "$TARGET_DIR" && "$FORCE" != 1 ]]; then
    printf '跳过 %s（已存在: %s）\n' "$skill" "$TARGET_DIR"
    skipped=$((skipped + 1))
    continue
  fi

  WORK_DIR="$TMP_DIR/$skill"
  mkdir -p "$WORK_DIR"
  case "$AGENT" in
    codex|omp)
      cat > "$WORK_DIR/SKILL.md" <<EOF
---
name: $skill
description: $DESCRIPTION
---

EOF
      ;;
    claude)
      cat > "$WORK_DIR/SKILL.md" <<EOF
---
name: $skill
description: $DESCRIPTION
---

EOF
      ;;
  esac
  cat "$SOURCE_DIR/instructions.md" >> "$WORK_DIR/SKILL.md"
  printf '\n' >> "$WORK_DIR/SKILL.md"
  if [[ -f "$SOURCE_DIR/examples.md" ]]; then
    cat "$SOURCE_DIR/examples.md" >> "$WORK_DIR/SKILL.md"
  else
    cat "$SOURCE_DIR/README.md" >> "$WORK_DIR/SKILL.md"
  fi

  if [[ "$FORCE" == 1 ]]; then
    rm -rf "$TARGET_DIR"
  fi
  mv "$WORK_DIR" "$TARGET_DIR"
  printf '已安装 %s skill: %s\n' "$skill" "$TARGET_DIR"
  installed=$((installed + 1))
done

printf '完成：安装 %d 个，跳过 %d 个。\n' "$installed" "$skipped"
