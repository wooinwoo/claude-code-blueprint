<p align="center">
  <img src="assets/cover.png" alt="Claude Code Blueprint" width="100%">
</p>

# CCB — Claude Code Blueprint

> One command. Four roles. Every project configured.

A production-grade Claude Code configuration system. Rules, commands, agents, skills, hooks, and MCP servers — layered by role, installed in one line.

```powershell
.\setup.ps1 react-next C:\path\to\project
```

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  LAYER 3: Stack / Profile                       │
│  react-next │ nestjs │ designer │ planner       │
│  Role-specific agents, commands, rules, skills  │
├─────────────────────────────────────────────────┤
│  LAYER 2: Common                                │
│  /commit, /jira, /code-review                   │
│  PR rules, MCP wrappers, shared settings        │
├─────────────────────────────────────────────────┤
│  LAYER 1: Base (swappable)                      │
│  Community agents, rules, skills                │
│  Synced via sync.ps1 — never edit directly      │
└─────────────────────────────────────────────────┘
                      │
                      │ setup.ps1
                      ▼
              project/.claude/
```

Each layer builds on the previous. Base is **swappable** — currently [everything-claude-code](https://github.com/affaan-m/everything-claude-code), but can be replaced with any source.

---

## What's Included

### Profiles

| Profile | Target | Agents | Commands | Rules | MCP |
|---------|--------|--------|----------|-------|-----|
| **react-next** | React/Next.js dev | 15 | 11 | 18 | 9 |
| **nestjs** | NestJS backend dev | 15 | 10 | 15 | 9 |
| **designer** | UI/UX + publishing | 3 | 6 | 4 | 6 |
| **planner** | PM / product planning | 3 | 11 | 3 | 4 |

### Dev (react-next, nestjs)

| Command | Description |
|---------|-------------|
| `/orchestrate` | 6-Phase pipeline: design → branch → implement → review → PR → cleanup |
| `/code-review` | 5 reviewer agents in parallel (code, convention, security, performance, feasibility) |
| `/build-fix` | lint → type → build error auto-fix loop |
| `/test-coverage` | Coverage analysis + auto-generate missing tests |
| `/commit` | Conventional commit with scope detection |

### Designer

| Command | Description |
|---------|-------------|
| `/design-system` | Token audit, component analysis, pattern suggestions |
| `/publish-check` | Lighthouse + Playwright responsive + source static analysis |
| `/figma-to-code` | Figma Dev Mode MCP → code generation |
| `/design-review` | 3 parallel agents: design, a11y, markup |
| `/design-qa` | Figma spec vs implementation comparison |
| `/discover` | Component inventory, unused/similar detection |

### Planner

| Command | Description |
|---------|-------------|
| `/research` | Research plan → WebSearch execution (market/user/tech) |
| `/prd` | 10-section PRD with completeness validation |
| `/story-map` | Walking Skeleton MVP verification |
| `/competitive-analysis` | Feature matrix + SWOT from WebSearch |
| `/okr` | OKR creation with quality gates (qualitative O, quantitative KR) |
| `/spec` | Lightweight feature spec with AC testability check |
| `/sprint-plan` | Capacity-based sprint planning with carryover |
| `/retro` | 4L / Starfish / Sailboat frameworks |
| `/launch` | Launch checklist + rollback plan + release notes |
| `/weekly-update` | Weekly report (default / team / exec modes) |
| `/roadmap` | RICE scoring + OKR alignment |

> All planner commands work without Jira. Graceful fallback to manual input.

---

## Quick Start

```powershell
# 1. Clone
git clone https://github.com/rstful/claude-code-blueprint.git

# 2. Install to your project
cd claude-code-blueprint
.\setup.ps1 react-next C:\path\to\my-project

# 3. Set tokens (optional)
notepad C:\path\to\my-project\.claude\.env
# GITHUB_PAT=ghp_xxx
# JIRA_TOKEN=xxx

# 4. Write CLAUDE.md
# Project overview, tech stack, structure, conventions
```

### Update

```powershell
cd claude-code-blueprint && git pull
.\setup.ps1 react-next C:\path\to\my-project   # re-install
```

---

## MCP Servers

| Server | Purpose | Profiles |
|--------|---------|----------|
| github | PR, issues, repos | all |
| mcp-atlassian | Jira issue management | all |
| context7 | Live npm/framework docs | all |
| memory | Cross-session persistence | all |
| figma-dev-mode | Figma design integration | designer |
| playwright | Browser automation | designer, dev |
| mysql | Database queries | dev |
| aws | AWS services | dev |

---

## Customization

```
common/rules/         → applies to all profiles
common/commands/       → applies to all profiles
react-next/rules/     → React projects only
designer/commands/     → designer profile only
planner/agents/        → planner profile only
```

`base/` is overwritten by `sync.ps1`. To modify base behavior, override in `common/` or your stack folder.

### Exclude System

```jsonc
// exclude.json — skip these from upstream sync
{
  "rules": ["golang", "python"],
  "agents": ["go-reviewer.md"],
  "skills": ["django-patterns"]
}
```

Excluded items are moved to `base/_excluded/` (preserved for reference, not deleted).

---

## Post-Install Checklist

1. **CLAUDE.md** — Write project overview, tech stack, structure
2. **.claude/.env** — Add tokens (GITHUB_PAT, JIRA_TOKEN)
3. **.mcp.json** — Remove unused MCP servers
4. **.claude/rules/project.md** — Add project-specific rules (optional)

---

## References

- Base upstream: [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [CLAUDE.md Guide](https://velog.io/@surim014/claude-md-guide)

---

<p align="center">
  <sub>Built with Claude Code. Configured by CCB.</sub>
</p>
