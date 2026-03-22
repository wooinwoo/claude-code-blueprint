<#
.SYNOPSIS
    프로젝트에 .claude 설정을 설치

.DESCRIPTION
    base/ + common/ + [stack]/ 을 프로젝트의 .claude/ 하위에 파일 복사로 설치합니다.
    모든 항목은 파일 복사이므로, 업데이트 시 setup.ps1 재실행이 필요합니다.

    Dev stacks: react-next, nestjs, java-web (base + common + stack 레이어)
    Non-dev profiles: designer, planner (stack 레이어만, base 선택적)

.EXAMPLE
    .\setup.ps1 react-next C:\my-react-project
    .\setup.ps1 nestjs C:\my-nestjs-project
    .\setup.ps1 java-web C:\my-java-project
    .\setup.ps1 designer C:\my-design-project
    .\setup.ps1 planner C:\my-planning-project
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet("react-next", "nestjs", "fullstack", "java-web", "designer", "planner")]
    [string]$Stack,

    [Parameter(Mandatory)]
    [string]$ProjectPath
)

$ErrorActionPreference = "Stop"
$CcbRoot = $PSScriptRoot

# 프로젝트 경로 확인
if (-not (Test-Path $ProjectPath)) {
    Write-Error "프로젝트 경로를 찾을 수 없습니다: $ProjectPath"
    exit 1
}

$claudeDir = Join-Path $ProjectPath ".claude"

# 프로필 타입 판별: dev (기존 3-layer) vs non-dev (designer/planner)
$DevStacks = @("react-next", "nestjs", "fullstack", "java-web")
$IsDevStack = $Stack -in $DevStacks

Write-Host "=== claude-code-blueprint setup ===" -ForegroundColor Cyan
Write-Host "Stack:   $Stack$(if (-not $IsDevStack) { ' (non-dev profile)' })" -ForegroundColor Gray
Write-Host "Project: $ProjectPath" -ForegroundColor Gray
Write-Host "Source:  $CcbRoot" -ForegroundColor Gray
Write-Host ""

# .claude 폴더 생성
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir | Out-Null
    Write-Host "  [NEW] .claude/ 생성" -ForegroundColor Green
}

# 스택 정보 저장 (update.ps1용)
$Stack | Out-File (Join-Path $claudeDir ".ccb-stack") -Encoding utf8 -NoNewline

# ============================================================
# 공통 복사 함수
# ============================================================
function Copy-LayerDir {
    param(
        [string]$TargetDir,
        [string]$Label,
        [string[]]$Sources,
        [switch]$Recurse,
        [switch]$CountDirs
    )

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir | Out-Null
    }

    Write-Host ""
    Write-Host "[$Label] 복사" -ForegroundColor White
    foreach ($src in $Sources) {
        if (-not (Test-Path $src)) { continue }
        Copy-Item "$src\*" $TargetDir -Recurse -Force
        if ($CountDirs) {
            $c = (Get-ChildItem $src -Directory).Count
            $layerName = Split-Path (Split-Path $src -Parent) -Leaf
            Write-Host "  [OK] $layerName ($c items)" -ForegroundColor Green
        } else {
            $c = if ($Recurse) { (Get-ChildItem $src -Recurse -File).Count } else { (Get-ChildItem $src -File).Count }
            $layerName = Split-Path (Split-Path $src -Parent) -Leaf
            Write-Host "  [OK] $layerName ($c files)" -ForegroundColor Green
        }
    }
}

# ============================================================
# rules/ - 서브디렉토리별 복사
# ============================================================
$rulesDir = Join-Path $claudeDir "rules"
if (-not (Test-Path $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir | Out-Null
}

Write-Host "[rules/] 복사" -ForegroundColor White

if ($IsDevStack) {
    # Dev stacks: base-common + base-typescript(조건) + ccb-common + ccb-stack
    $rulesSources = @(
        @{ Name = "base-common";    Path = "$CcbRoot\base\rules\common" }
    )
    if ($Stack -ne "java-web") {
        $rulesSources += @{ Name = "base-typescript"; Path = "$CcbRoot\base\rules\typescript" }
    }
    $rulesSources += @(
        @{ Name = "ccb-common";     Path = "$CcbRoot\common\rules" },
        @{ Name = "ccb-stack";      Path = "$CcbRoot\$Stack\rules" }
    )
} else {
    # Non-dev profiles: base-common에서 필요한 것만 + ccb-common + profile rules
    # 개발 전용 룰(coding-style, testing, security, patterns 등) 제외
    $nonDevBaseRulesAllow = @("git-workflow.md", "agents.md")

    # base-common에서 허용 목록만 복사
    $baseCommonTemp = Join-Path $env:TEMP "ccb-base-common-filtered-$(Get-Random)"
    if (Test-Path $baseCommonTemp) { Remove-Item $baseCommonTemp -Recurse -Force }
    New-Item -ItemType Directory -Path $baseCommonTemp -Force | Out-Null
    foreach ($f in $nonDevBaseRulesAllow) {
        $src = Join-Path "$CcbRoot\base\rules\common" $f
        if (Test-Path $src) { Copy-Item $src $baseCommonTemp }
    }

    $rulesSources = @(
        @{ Name = "base-common";    Path = $baseCommonTemp },
        @{ Name = "ccb-common";     Path = "$CcbRoot\common\rules" },
        @{ Name = "ccb-$Stack";     Path = "$CcbRoot\$Stack\rules" }
    )
}

foreach ($rule in $rulesSources) {
    if (-not (Test-Path $rule.Path)) { continue }
    $dest = Join-Path $rulesDir $rule.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $rule.Path $dest -Recurse -Force
    $c = (Get-ChildItem $rule.Path -File -Recurse).Count
    Write-Host "  [OK] $($rule.Name) ($c files)" -ForegroundColor Green
}

# ============================================================
# agents/ - 파일 복사
# ============================================================
if ($IsDevStack) {
    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "agents") `
        -Label "agents/" `
        -Sources @(
            "$CcbRoot\base\agents",
            "$CcbRoot\common\agents",
            "$CcbRoot\$Stack\agents"
        )
} else {
    # Non-dev: profile agents only (base/common 개발 에이전트 불필요)
    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "agents") `
        -Label "agents/" `
        -Sources @(
            "$CcbRoot\$Stack\agents"
        )
}

# ============================================================
# commands/ - 파일 복사
# ============================================================
if ($IsDevStack) {
    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "commands") `
        -Label "commands/" `
        -Sources @(
            "$CcbRoot\base\commands",
            "$CcbRoot\common\commands",
            "$CcbRoot\$Stack\commands"
        ) -Recurse
} else {
    # Non-dev: common 유틸 커맨드(개발 무관) + profile 커맨드
    $nonDevCommonCmdsAllow = @("commit.md", "jira.md", "guide.md")

    $commonCmdsTemp = Join-Path $env:TEMP "ccb-common-cmds-filtered-$(Get-Random)"
    if (Test-Path $commonCmdsTemp) { Remove-Item $commonCmdsTemp -Recurse -Force }
    New-Item -ItemType Directory -Path $commonCmdsTemp -Force | Out-Null
    foreach ($c in $nonDevCommonCmdsAllow) {
        $src = Join-Path "$CcbRoot\common\commands" $c
        if (Test-Path $src) { Copy-Item $src $commonCmdsTemp }
    }

    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "commands") `
        -Label "commands/" `
        -Sources @(
            $commonCmdsTemp,
            "$CcbRoot\$Stack\commands"
        ) -Recurse
}

# ============================================================
# skills/ - 파일 복사
# ============================================================
if ($IsDevStack) {
    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "skills") `
        -Label "skills/" `
        -Sources @(
            "$CcbRoot\base\skills",
            "$CcbRoot\common\skills",
            "$CcbRoot\$Stack\skills"
        ) -CountDirs
} else {
    # Non-dev: base 스킬 중 개발 무관한 것만 + profile 스킬
    $nonDevBaseSkillsAllow = @("strategic-compact", "iterative-retrieval", "search-first")

    $baseSkillsTemp = Join-Path $env:TEMP "ccb-base-skills-filtered-$(Get-Random)"
    if (Test-Path $baseSkillsTemp) { Remove-Item $baseSkillsTemp -Recurse -Force }
    New-Item -ItemType Directory -Path $baseSkillsTemp -Force | Out-Null
    foreach ($s in $nonDevBaseSkillsAllow) {
        $src = Join-Path "$CcbRoot\base\skills" $s
        if (Test-Path $src) { Copy-Item $src $baseSkillsTemp -Recurse }
    }

    Copy-LayerDir `
        -TargetDir (Join-Path $claudeDir "skills") `
        -Label "skills/" `
        -Sources @(
            $baseSkillsTemp,
            "$CcbRoot\$Stack\skills"
        ) -CountDirs
}

# ============================================================
# hooks/ - 파일 복사
# ============================================================
$hooksDir = Join-Path $claudeDir "hooks"
if (Test-Path $hooksDir) {
    # 기존 junction이면 제거
    $item = Get-Item $hooksDir -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        cmd /c rmdir "$hooksDir" 2>$null
    }
}
if ($IsDevStack) {
    Copy-LayerDir `
        -TargetDir $hooksDir `
        -Label "hooks/" `
        -Sources @("$CcbRoot\base\hooks") -Recurse
} else {
    # Non-dev: profile 전용 hooks (base hooks는 개발 도구 중심이라 불필요)
    Copy-LayerDir `
        -TargetDir $hooksDir `
        -Label "hooks/" `
        -Sources @("$CcbRoot\$Stack\hooks") -Recurse
}

# ============================================================
# contexts/ - 파일 복사
# ============================================================
$contextsDir = Join-Path $claudeDir "contexts"
if (Test-Path $contextsDir) {
    $item = Get-Item $contextsDir -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        cmd /c rmdir "$contextsDir" 2>$null
    }
}
if ($IsDevStack) {
    Copy-LayerDir `
        -TargetDir $contextsDir `
        -Label "contexts/" `
        -Sources @("$CcbRoot\base\contexts") -Recurse
} else {
    # Non-dev: base contexts + profile contexts
    Copy-LayerDir `
        -TargetDir $contextsDir `
        -Label "contexts/" `
        -Sources @(
            "$CcbRoot\base\contexts",
            "$CcbRoot\$Stack\contexts"
        ) -Recurse
}

# ============================================================
# scripts/ - 파일 복사 (base: hook 스크립트) — dev stacks만
# ============================================================
if ($IsDevStack) {
    $scriptsDir = Join-Path $claudeDir "scripts"
    if (Test-Path $scriptsDir) {
        $item = Get-Item $scriptsDir -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            cmd /c rmdir "$scriptsDir" 2>$null
        }
    }
    Copy-LayerDir `
        -TargetDir $scriptsDir `
        -Label "scripts/" `
        -Sources @("$CcbRoot\base\scripts") -Recurse

    # scripts/ npm install (node-notifier 등)
    $scriptsPkg = Join-Path $scriptsDir "package.json"
    if (Test-Path $scriptsPkg) {
        $nodeModules = Join-Path $scriptsDir "node_modules"
        if (-not (Test-Path $nodeModules)) {
            Write-Host "  [NPM] scripts/ 의존성 설치 중..." -ForegroundColor Yellow
            Push-Location $scriptsDir
            npm install --silent 2>$null
            Pop-Location
            Write-Host "  [OK] node-notifier 설치 완료" -ForegroundColor Green
        }
    }
}

# ============================================================
# scripts-ccb/ - 파일 복사 (common: MCP 래퍼 스크립트)
# ============================================================
$scriptsWiwDir = Join-Path $claudeDir "scripts-ccb"
if (Test-Path $scriptsWiwDir) {
    $item = Get-Item $scriptsWiwDir -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        cmd /c rmdir "$scriptsWiwDir" 2>$null
    }
}
Copy-LayerDir `
    -TargetDir $scriptsWiwDir `
    -Label "scripts-ccb/" `
    -Sources @("$CcbRoot\common\scripts") -Recurse

# ============================================================
# settings.json — 권한 설정 (없을 때만)
# ============================================================
Write-Host ""
Write-Host "[settings] 권한 설정" -ForegroundColor White
$settingsJson = Join-Path $claudeDir "settings.json"
if ($IsDevStack) {
    $settingsTemplate = Join-Path $CcbRoot "common\settings.json"
} else {
    $settingsTemplate = Join-Path $CcbRoot "$Stack\settings.json"
}
if (-not (Test-Path $settingsJson) -and (Test-Path $settingsTemplate)) {
    Copy-Item $settingsTemplate $settingsJson
    Write-Host "  [NEW] settings.json 생성 (Bash 권한 사전 허용)" -ForegroundColor Yellow
} else {
    Write-Host "  [SKIP] settings.json 이미 존재" -ForegroundColor Gray
}

# ============================================================
# .mcp.json 복사 (없을 때만)
# ============================================================
Write-Host ""
Write-Host "[MCP] 설정" -ForegroundColor White
$mcpJson = Join-Path $ProjectPath ".mcp.json"
if ($IsDevStack) {
    $mcpTemplate = Join-Path $CcbRoot "common\mcp-configs\.mcp.json"
} else {
    $mcpTemplate = Join-Path $CcbRoot "$Stack\mcp-configs\.mcp.json"
}
if (-not (Test-Path $mcpJson) -and (Test-Path $mcpTemplate)) {
    Copy-Item $mcpTemplate $mcpJson
    Write-Host "  [NEW] .mcp.json 생성 (필요 없는 서버는 제거하세요)" -ForegroundColor Yellow
} else {
    Write-Host "  [SKIP] .mcp.json 이미 존재" -ForegroundColor Gray
}

# .env 파일 안내 (.env.example 복사)
$envFile = Join-Path $claudeDir ".env"
$envExample = Join-Path $CcbRoot "common\.env.example"
if (-not (Test-Path $envFile) -and (Test-Path $envExample)) {
    Copy-Item $envExample $envFile
    Write-Host "  [NEW] .claude/.env 생성 (토큰을 직접 입력하세요)" -ForegroundColor Yellow
} elseif (Test-Path $envFile) {
    # 기존 .env에 CLAUDE_PLUGIN_ROOT 없으면 추가
    $envContent = Get-Content $envFile -Raw
    if ($envContent -notmatch "CLAUDE_PLUGIN_ROOT") {
        Add-Content $envFile "`n# hooks/scripts 경로 (변경하지 마세요)`nCLAUDE_PLUGIN_ROOT=.claude"
        Write-Host "  [OK] .env에 CLAUDE_PLUGIN_ROOT 추가" -ForegroundColor Green
    }
}

# ============================================================
# homunculus 디렉토리 초기화 (continuous-learning-v2)
# ============================================================
$homunculusDir = Join-Path $claudeDir "homunculus"
if (-not (Test-Path $homunculusDir)) {
    New-Item -ItemType Directory -Path "$homunculusDir\instincts\personal" -Force | Out-Null
    New-Item -ItemType Directory -Path "$homunculusDir\instincts\inherited" -Force | Out-Null
    New-Item -ItemType Directory -Path "$homunculusDir\evolved\agents" -Force | Out-Null
    New-Item -ItemType Directory -Path "$homunculusDir\evolved\skills" -Force | Out-Null
    New-Item -ItemType Directory -Path "$homunculusDir\evolved\commands" -Force | Out-Null
    New-Item -ItemType File -Path "$homunculusDir\observations.jsonl" -Force | Out-Null
    Write-Host ""
    Write-Host "  [NEW] homunculus/ 디렉토리 생성 (학습 시스템)" -ForegroundColor Green
}

# ============================================================
# CLAUDE.md 생성 (없을 때만)
# ============================================================
$claudeMd = Join-Path $ProjectPath "CLAUDE.md"
if (-not (Test-Path $claudeMd)) {
    $projectName = Split-Path $ProjectPath -Leaf
    if ($IsDevStack) {
        @"
# $projectName

## Project Overview

<!-- 프로젝트 설명을 여기에 작성하세요 -->

## When writing code (IMPORTANT)

- Do not use abstract words for all function names, variable names (e.g. Info, Data, Item, Manager, Handler, Process, Helper, Util)
- Use specific, descriptive names that convey intent

## Setup

- claude-code-blueprint: $Stack
- template version: $(Get-Content "$CcbRoot\VERSION" -ErrorAction SilentlyContinue)
"@ | Out-File $claudeMd -Encoding utf8
    } elseif ($Stack -eq "designer") {
        @"
# $projectName

## Project Overview

<!-- 프로젝트 설명을 여기에 작성하세요 -->

## Design Principles

- 모바일 퍼스트, 접근성 AA 기본
- 디자인 토큰/시스템 일관성 유지
- "AI스러운" 제네릭 결과물 경계 — 독창적이고 의도적인 디자인 추구
- 실제 콘텐츠로 디자인 (Lorem ipsum 금지)

## Design System

<!-- 사용 중인 디자인 시스템/토큰 정보를 작성하세요 -->

## Setup

- claude-code-blueprint: $Stack
- template version: $(Get-Content "$CcbRoot\VERSION" -ErrorAction SilentlyContinue)
"@ | Out-File $claudeMd -Encoding utf8
    } elseif ($Stack -eq "planner") {
        @"
# $projectName

## Project Overview

<!-- 프로젝트/제품 설명을 여기에 작성하세요 -->

## Product Context

<!-- 제품 비전, 타겟 사용자, 핵심 지표를 작성하세요 -->

## Document Conventions

- 모든 문서는 plans/ 디렉토리에 저장
- 데이터 근거 필수 (출처, 날짜, 신뢰도)
- 액션 아이템으로 마무리

## Setup

- claude-code-blueprint: $Stack
- template version: $(Get-Content "$CcbRoot\VERSION" -ErrorAction SilentlyContinue)
"@ | Out-File $claudeMd -Encoding utf8
    }
    Write-Host ""
    Write-Host "  [NEW] CLAUDE.md 생성 (직접 수정하세요)" -ForegroundColor Green
}

# ============================================================
# .gitignore 에 관리 항목 추가
# ============================================================
$gitignore = Join-Path $ProjectPath ".gitignore"
$ignoreEntries = @(
    "# claude-code-blueprint (setup.ps1로 관리)"
    ".claude/.env"
    ".claude/.ccb-stack"
    ".claude/settings.local.json"
    ".claude/homunculus/"
    "CLAUDE.local.md"
    ".orchestrate/"
    "worktrees/"
    "plans/"
)

if (Test-Path $gitignore) {
    $existing = Get-Content $gitignore -Raw
    if ($existing -notmatch "claude-code-blueprint") {
        $ignoreEntries -join "`n" | Add-Content $gitignore
        Write-Host ""
        Write-Host "  [OK] .gitignore 업데이트" -ForegroundColor Green
    }
} else {
    $ignoreEntries -join "`n" | Out-File $gitignore -Encoding utf8
    Write-Host ""
    Write-Host "  [NEW] .gitignore 생성" -ForegroundColor Green
}

# ============================================================
# 완료
# ============================================================
Write-Host ""
Write-Host "=== setup 완료 ===" -ForegroundColor Cyan
Write-Host ""

if ($IsDevStack) {
    Write-Host "설치 내역 (모두 파일 복사):" -ForegroundColor White
    Write-Host "  rules/        base + ccb-common + ccb-$Stack" -ForegroundColor Gray
    Write-Host "  agents/       base + common + $Stack" -ForegroundColor Gray
    Write-Host "  commands/     base + common + $Stack" -ForegroundColor Gray
    Write-Host "  skills/       base + common + $Stack" -ForegroundColor Gray
    Write-Host "  hooks/        base" -ForegroundColor Gray
    Write-Host "  scripts/      base (hook 스크립트)" -ForegroundColor Gray
    Write-Host "  scripts-ccb/  common (MCP 래퍼)" -ForegroundColor Gray
    Write-Host "  .mcp.json     MCP 서버 설정" -ForegroundColor Gray
} else {
    Write-Host "설치 내역 ($Stack profile):" -ForegroundColor White
    Write-Host "  rules/        base-common + ccb-common + $Stack" -ForegroundColor Gray
    Write-Host "  agents/       $Stack" -ForegroundColor Gray
    Write-Host "  commands/     $Stack" -ForegroundColor Gray
    Write-Host "  skills/       base + $Stack" -ForegroundColor Gray
    Write-Host "  hooks/        $Stack" -ForegroundColor Gray
    Write-Host "  contexts/     base + $Stack" -ForegroundColor Gray
    Write-Host "  scripts-ccb/  common (MCP 래퍼)" -ForegroundColor Gray
    Write-Host "  .mcp.json     $Stack MCP 서버 설정" -ForegroundColor Gray
}

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor White
Write-Host "  1. CLAUDE.md에 프로젝트 설명 작성" -ForegroundColor Gray
if ($IsDevStack) {
    Write-Host "  2. .claude/rules/project.md 에 프로젝트 전용 규칙 추가 (선택)" -ForegroundColor Gray
    Write-Host "  3. .claude/.env 에 토큰 입력 (GitHub PAT, Jira Token, DATABASE_URL)" -ForegroundColor Gray
} else {
    Write-Host "  2. .claude/.env 에 토큰 입력 (GitHub PAT, Jira Token)" -ForegroundColor Gray
}
Write-Host "  $(if ($IsDevStack) { '4' } else { '3' }). .mcp.json 에서 필요 없는 MCP 서버 제거" -ForegroundColor Gray
Write-Host ""
Write-Host "claude-code-blueprint 업데이트 후 setup.ps1 재실행하면 반영됩니다." -ForegroundColor DarkGray
