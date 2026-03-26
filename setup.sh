#!/usr/bin/env bash
# ============================================================
# CCB setup.sh — macOS/Linux/WSL용 프로젝트 설치 스크립트
# setup.ps1의 bash 포팅
#
# Usage:
#   ./setup.sh react-next /path/to/project
#   ./setup.sh nestjs /path/to/project
#   ./setup.sh fullstack /path/to/project
#   ./setup.sh designer /path/to/project
#   ./setup.sh planner /path/to/project
# ============================================================

set -e

STACK="$1"
PROJECT_PATH="$2"
CCB_ROOT="$(cd "$(dirname "$0")" && pwd)"
VERSION=$(cat "$CCB_ROOT/VERSION" 2>/dev/null || echo "unknown")

# 색상
C_CYAN='\033[0;36m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_GRAY='\033[0;90m'
C_WHITE='\033[1;37m'
C_RESET='\033[0m'

# ============================================================
# 인수 검증
# ============================================================
VALID_STACKS="react-next nestjs fullstack java-web designer planner"
if [[ -z "$STACK" || -z "$PROJECT_PATH" ]]; then
  echo "Usage: ./setup.sh <stack> <project-path>"
  echo "Stacks: $VALID_STACKS"
  exit 1
fi

if ! echo "$VALID_STACKS" | grep -qw "$STACK"; then
  echo "Error: Invalid stack '$STACK'"
  echo "Valid: $VALID_STACKS"
  exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: Project path not found: $PROJECT_PATH"
  exit 1
fi

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
CLAUDE_DIR="$PROJECT_PATH/.claude"

# 프로필 타입 판별
DEV_STACKS="react-next nestjs fullstack java-web"
IS_DEV=false
if echo "$DEV_STACKS" | grep -qw "$STACK"; then
  IS_DEV=true
fi

PROFILE_LABEL="$STACK"
if [ "$IS_DEV" = false ]; then
  PROFILE_LABEL="$STACK (non-dev profile)"
fi

echo -e "${C_CYAN}=== claude-code-blueprint setup ===${C_RESET}"
echo -e "${C_GRAY}Stack:   $PROFILE_LABEL${C_RESET}"
echo -e "${C_GRAY}Project: $PROJECT_PATH${C_RESET}"
echo -e "${C_GRAY}Source:  $CCB_ROOT${C_RESET}"
echo ""

# .claude 폴더 생성
if [ ! -d "$CLAUDE_DIR" ]; then
  mkdir -p "$CLAUDE_DIR"
  echo -e "  ${C_GREEN}[NEW] .claude/ 생성${C_RESET}"
fi

# 스택 정보 저장
echo -n "$STACK" > "$CLAUDE_DIR/.ccb-stack"

# ============================================================
# 공통 복사 함수
# ============================================================
copy_layer() {
  local target="$1"
  local label="$2"
  shift 2
  local sources=("$@")

  mkdir -p "$target"

  for src in "${sources[@]}"; do
    [ ! -d "$src" ] && continue
    cp -r "$src"/* "$target/" 2>/dev/null || true
    local count=$(find "$src" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    local layer=$(basename "$(dirname "$src")")
    echo -e "  ${C_GREEN}[OK] $layer ($count files)${C_RESET}"
  done
}

copy_layer_dirs() {
  local target="$1"
  local label="$2"
  shift 2
  local sources=("$@")

  mkdir -p "$target"

  for src in "${sources[@]}"; do
    [ ! -d "$src" ] && continue
    cp -r "$src"/* "$target/" 2>/dev/null || true
    local count=$(find "$src" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    count=$((count - 1))
    local layer=$(basename "$(dirname "$src")")
    echo -e "  ${C_GREEN}[OK] $layer ($count items)${C_RESET}"
  done
}

# ============================================================
# rules/
# ============================================================
RULES_DIR="$CLAUDE_DIR/rules"
mkdir -p "$RULES_DIR"

echo -e "${C_WHITE}[rules/] 복사${C_RESET}"

if [ "$IS_DEV" = true ]; then
  # base-common
  if [ -d "$CCB_ROOT/base/rules/common" ]; then
    rm -rf "$RULES_DIR/base-common"
    cp -r "$CCB_ROOT/base/rules/common" "$RULES_DIR/base-common"
    echo -e "  ${C_GREEN}[OK] base-common ($(ls "$CCB_ROOT/base/rules/common"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
  # base-typescript (java-web 제외)
  if [ "$STACK" != "java-web" ] && [ -d "$CCB_ROOT/base/rules/typescript" ]; then
    rm -rf "$RULES_DIR/base-typescript"
    cp -r "$CCB_ROOT/base/rules/typescript" "$RULES_DIR/base-typescript"
    echo -e "  ${C_GREEN}[OK] base-typescript ($(ls "$CCB_ROOT/base/rules/typescript"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
  # ccb-common
  if [ -d "$CCB_ROOT/common/rules" ]; then
    rm -rf "$RULES_DIR/ccb-common"
    cp -r "$CCB_ROOT/common/rules" "$RULES_DIR/ccb-common"
    echo -e "  ${C_GREEN}[OK] ccb-common ($(ls "$CCB_ROOT/common/rules"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
  # ccb-stack
  if [ -d "$CCB_ROOT/$STACK/rules" ]; then
    rm -rf "$RULES_DIR/ccb-stack"
    cp -r "$CCB_ROOT/$STACK/rules" "$RULES_DIR/ccb-stack"
    echo -e "  ${C_GREEN}[OK] ccb-stack ($(ls "$CCB_ROOT/$STACK/rules"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
else
  # Non-dev: base-common에서 필요한 것만
  NON_DEV_RULES=("git-workflow.md" "agents.md")
  TEMP_RULES=$(mktemp -d)
  for f in "${NON_DEV_RULES[@]}"; do
    [ -f "$CCB_ROOT/base/rules/common/$f" ] && cp "$CCB_ROOT/base/rules/common/$f" "$TEMP_RULES/"
  done
  rm -rf "$RULES_DIR/base-common"
  cp -r "$TEMP_RULES" "$RULES_DIR/base-common"
  echo -e "  ${C_GREEN}[OK] base-common (${#NON_DEV_RULES[@]} files)${C_RESET}"
  rm -rf "$TEMP_RULES"

  # ccb-common
  if [ -d "$CCB_ROOT/common/rules" ]; then
    rm -rf "$RULES_DIR/ccb-common"
    cp -r "$CCB_ROOT/common/rules" "$RULES_DIR/ccb-common"
    echo -e "  ${C_GREEN}[OK] ccb-common ($(ls "$CCB_ROOT/common/rules"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
  # ccb-stack
  if [ -d "$CCB_ROOT/$STACK/rules" ]; then
    rm -rf "$RULES_DIR/ccb-$STACK"
    cp -r "$CCB_ROOT/$STACK/rules" "$RULES_DIR/ccb-$STACK"
    echo -e "  ${C_GREEN}[OK] ccb-$STACK ($(ls "$CCB_ROOT/$STACK/rules"/*.md 2>/dev/null | wc -l | tr -d ' ') files)${C_RESET}"
  fi
fi

# ============================================================
# agents/
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer "$CLAUDE_DIR/agents" "agents/" \
    "$CCB_ROOT/base/agents" "$CCB_ROOT/common/agents" "$CCB_ROOT/$STACK/agents"
else
  copy_layer "$CLAUDE_DIR/agents" "agents/" "$CCB_ROOT/$STACK/agents"
fi

# ============================================================
# commands/
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer "$CLAUDE_DIR/commands" "commands/" \
    "$CCB_ROOT/base/commands" "$CCB_ROOT/common/commands" "$CCB_ROOT/$STACK/commands"
else
  # Non-dev: common 유틸만 + profile
  NON_DEV_CMDS=("commit.md" "jira.md" "guide.md")
  TEMP_CMDS=$(mktemp -d)
  for f in "${NON_DEV_CMDS[@]}"; do
    [ -f "$CCB_ROOT/common/commands/$f" ] && cp "$CCB_ROOT/common/commands/$f" "$TEMP_CMDS/"
  done
  copy_layer "$CLAUDE_DIR/commands" "commands/" "$TEMP_CMDS" "$CCB_ROOT/$STACK/commands"
  rm -rf "$TEMP_CMDS"
fi

# ============================================================
# skills/
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer_dirs "$CLAUDE_DIR/skills" "skills/" \
    "$CCB_ROOT/base/skills" "$CCB_ROOT/common/skills" "$CCB_ROOT/$STACK/skills"
else
  # Non-dev: base 스킬 중 일부만
  NON_DEV_SKILLS=("strategic-compact" "iterative-retrieval" "search-first")
  TEMP_SKILLS=$(mktemp -d)
  for s in "${NON_DEV_SKILLS[@]}"; do
    [ -d "$CCB_ROOT/base/skills/$s" ] && cp -r "$CCB_ROOT/base/skills/$s" "$TEMP_SKILLS/"
  done
  copy_layer_dirs "$CLAUDE_DIR/skills" "skills/" "$TEMP_SKILLS" "$CCB_ROOT/$STACK/skills"
  rm -rf "$TEMP_SKILLS"
fi

# ============================================================
# hooks/
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer "$CLAUDE_DIR/hooks" "hooks/" "$CCB_ROOT/base/hooks"
else
  copy_layer "$CLAUDE_DIR/hooks" "hooks/" "$CCB_ROOT/$STACK/hooks"
fi

# ============================================================
# contexts/
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer "$CLAUDE_DIR/contexts" "contexts/" "$CCB_ROOT/base/contexts"
else
  copy_layer "$CLAUDE_DIR/contexts" "contexts/" "$CCB_ROOT/base/contexts" "$CCB_ROOT/$STACK/contexts"
fi

# ============================================================
# scripts/ (dev only)
# ============================================================
if [ "$IS_DEV" = true ]; then
  copy_layer "$CLAUDE_DIR/scripts" "scripts/" "$CCB_ROOT/base/scripts"
  # npm install for hook scripts
  if [ -f "$CLAUDE_DIR/scripts/package.json" ] && [ ! -d "$CLAUDE_DIR/scripts/node_modules" ]; then
    echo -e "  ${C_YELLOW}[NPM] scripts/ 의존성 설치 중...${C_RESET}"
    (cd "$CLAUDE_DIR/scripts" && npm install --silent 2>/dev/null)
    echo -e "  ${C_GREEN}[OK] 설치 완료${C_RESET}"
  fi
fi

# ============================================================
# scripts-ccb/ (MCP 래퍼)
# ============================================================
copy_layer "$CLAUDE_DIR/scripts-ccb" "scripts-ccb/" "$CCB_ROOT/common/scripts"

# ============================================================
# settings.json (없을 때만)
# ============================================================
echo ""
echo -e "${C_WHITE}[settings] 권한 설정${C_RESET}"
SETTINGS="$CLAUDE_DIR/settings.json"
if [ "$IS_DEV" = true ]; then
  SETTINGS_TMPL="$CCB_ROOT/common/settings.json"
else
  SETTINGS_TMPL="$CCB_ROOT/$STACK/settings.json"
fi
if [ ! -f "$SETTINGS" ] && [ -f "$SETTINGS_TMPL" ]; then
  cp "$SETTINGS_TMPL" "$SETTINGS"
  echo -e "  ${C_YELLOW}[NEW] settings.json 생성${C_RESET}"
else
  echo -e "  ${C_GRAY}[SKIP] settings.json 이미 존재${C_RESET}"
fi

# ============================================================
# .mcp.json (없을 때만)
# ============================================================
echo ""
echo -e "${C_WHITE}[MCP] 설정${C_RESET}"
MCP_JSON="$PROJECT_PATH/.mcp.json"
if [ "$IS_DEV" = true ]; then
  MCP_TMPL="$CCB_ROOT/common/mcp-configs/.mcp.json"
else
  MCP_TMPL="$CCB_ROOT/$STACK/mcp-configs/.mcp.json"
fi
if [ ! -f "$MCP_JSON" ] && [ -f "$MCP_TMPL" ]; then
  cp "$MCP_TMPL" "$MCP_JSON"
  echo -e "  ${C_YELLOW}[NEW] .mcp.json 생성${C_RESET}"
else
  echo -e "  ${C_GRAY}[SKIP] .mcp.json 이미 존재${C_RESET}"
fi

# .env
ENV_FILE="$CLAUDE_DIR/.env"
ENV_EXAMPLE="$CCB_ROOT/common/.env.example"
if [ ! -f "$ENV_FILE" ] && [ -f "$ENV_EXAMPLE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo -e "  ${C_YELLOW}[NEW] .claude/.env 생성${C_RESET}"
fi

# ============================================================
# homunculus/
# ============================================================
if [ ! -d "$CLAUDE_DIR/homunculus" ]; then
  mkdir -p "$CLAUDE_DIR/homunculus/instincts/personal"
  mkdir -p "$CLAUDE_DIR/homunculus/instincts/inherited"
  mkdir -p "$CLAUDE_DIR/homunculus/evolved/agents"
  mkdir -p "$CLAUDE_DIR/homunculus/evolved/skills"
  mkdir -p "$CLAUDE_DIR/homunculus/evolved/commands"
  touch "$CLAUDE_DIR/homunculus/observations.jsonl"
  echo ""
  echo -e "  ${C_GREEN}[NEW] homunculus/ 생성${C_RESET}"
fi

# ============================================================
# CLAUDE.md (없을 때만)
# ============================================================
CLAUDE_MD="$PROJECT_PATH/CLAUDE.md"
PROJECT_NAME=$(basename "$PROJECT_PATH")
if [ ! -f "$CLAUDE_MD" ]; then
  if [ "$IS_DEV" = true ]; then
    cat > "$CLAUDE_MD" << EOF
# $PROJECT_NAME

## Project Overview

<!-- 프로젝트 설명을 여기에 작성하세요 -->

## When writing code (IMPORTANT)

- Do not use abstract words for all function names, variable names (e.g. Info, Data, Item, Manager, Handler, Process, Helper, Util)
- Use specific, descriptive names that convey intent

## Setup

- claude-code-blueprint: $STACK
- template version: $VERSION
EOF
  elif [ "$STACK" = "designer" ]; then
    cat > "$CLAUDE_MD" << EOF
# $PROJECT_NAME

## Project Overview

<!-- 프로젝트 설명을 여기에 작성하세요 -->

## Design Principles

- 모바일 퍼스트, 접근성 AA 기본
- 디자인 토큰/시스템 일관성 유지
- "AI스러운" 제네릭 결과물 경계
- 실제 콘텐츠로 디자인 (Lorem ipsum 금지)

## Setup

- claude-code-blueprint: $STACK
- template version: $VERSION
EOF
  elif [ "$STACK" = "planner" ]; then
    cat > "$CLAUDE_MD" << EOF
# $PROJECT_NAME

## Project Overview

<!-- 프로젝트/제품 설명을 여기에 작성하세요 -->

## Document Conventions

- 모든 문서는 plans/ 디렉토리에 저장
- 데이터 근거 필수 (출처, 날짜, 신뢰도)
- 액션 아이템으로 마무리

## Setup

- claude-code-blueprint: $STACK
- template version: $VERSION
EOF
  fi
  echo ""
  echo -e "  ${C_GREEN}[NEW] CLAUDE.md 생성${C_RESET}"
fi

# ============================================================
# .gitignore
# ============================================================
GITIGNORE="$PROJECT_PATH/.gitignore"
IGNORE_ENTRIES="# claude-code-blueprint (setup.sh로 관리)
.claude/.env
.claude/.ccb-stack
.claude/settings.local.json
.claude/homunculus/
CLAUDE.local.md
.orchestrate/
worktrees/
plans/"

if [ -f "$GITIGNORE" ]; then
  if ! grep -q "claude-code-blueprint" "$GITIGNORE"; then
    echo "" >> "$GITIGNORE"
    echo "$IGNORE_ENTRIES" >> "$GITIGNORE"
    echo ""
    echo -e "  ${C_GREEN}[OK] .gitignore 업데이트${C_RESET}"
  fi
else
  echo "$IGNORE_ENTRIES" > "$GITIGNORE"
  echo ""
  echo -e "  ${C_GREEN}[NEW] .gitignore 생성${C_RESET}"
fi

# ============================================================
# 완료
# ============================================================
echo ""
echo -e "${C_CYAN}=== setup 완료 ===${C_RESET}"
echo ""
echo -e "${C_WHITE}다음 단계:${C_RESET}"
echo -e "${C_GRAY}  1. CLAUDE.md에 프로젝트 설명 작성${C_RESET}"
echo -e "${C_GRAY}  2. .claude/.env 에 토큰 입력 (GitHub PAT, Jira Token)${C_RESET}"
echo -e "${C_GRAY}  3. .mcp.json 에서 필요 없는 MCP 서버 제거${C_RESET}"
echo ""
echo -e "${C_GRAY}claude-code-blueprint 업데이트 후 setup.sh 재실행하면 반영됩니다.${C_RESET}"
