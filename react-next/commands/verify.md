# Verification Command — React/Vite/Next.js

Run comprehensive verification on current codebase state.

## Instructions

Execute verification in this exact order:

1. **Build Check**
   - Run `pnpm build` (Vite) or `pnpm next build` (Next.js)
   - If it fails, report errors and STOP

2. **Type Check**
   - Run `pnpm tsc --noEmit`
   - Report all errors with file:line

3. **Lint Check**
   - Run `pnpm lint`
   - Report warnings and errors

4. **Test Suite**
   - Run `pnpm test` (or `pnpm vitest run` if no test script)
   - Report pass/fail count
   - Report coverage percentage

5. **Console.log Audit**
   - Search for `console.log` in `src/` files (exclude `*.test.*`, `*.spec.*`, `mock-data.*`)
   - Report locations

6. **Git Status**
   - Show uncommitted changes
   - Show files modified since last commit

7. **Bundle Analysis** (only for `full` and `pre-pr`)
   - Run `pnpm build` with stats if available
   - Report: total bundle size, largest chunks (top 5)
   - Flag chunks > 250KB as warnings

8. **Accessibility Spot Check** (only for `pre-pr`)
   - Grep for common a11y issues in changed files:
     - `<img` without `alt`
     - `onClick` on non-interactive elements without `role` and `tabIndex`
     - `<div onClick` without keyboard handler

## Output

Produce a concise verification report:

```
VERIFICATION: [PASS/FAIL]

Build:    [OK/FAIL]
Types:    [OK/X errors]
Lint:     [OK/X issues]
Tests:    [X/Y passed, Z% coverage]
Logs:     [OK/X console.logs]
Bundle:   [X KB total, largest: Y KB] (full/pre-pr only)
A11y:     [OK/X issues] (pre-pr only)

Ready for PR: [YES/NO]
```

If any critical issues, list them with fix suggestions.

## Arguments

$ARGUMENTS can be:
- `quick` - Only build + types
- `full` - All checks including bundle analysis (default)
- `pre-commit` - Build + types + lint + console.log audit
- `pre-pr` - Full checks + bundle analysis + a11y spot check
