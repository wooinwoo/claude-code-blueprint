#!/usr/bin/env node
/**
 * verify용 검증 스크립트
 * lint, type-check, build, test를 순차 실행하고 결과를 JSON으로 출력
 *
 * 사용법: node run-verify.js
 * 출력: stdout에 JSON
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// 패키지 매니저 감지
function detectPm() {
  if (fs.existsSync('pnpm-lock.yaml')) return 'pnpm';
  if (fs.existsSync('yarn.lock')) return 'yarn';
  if (fs.existsSync('bun.lockb')) return 'bun';
  if (fs.existsSync('package-lock.json')) return 'npm';
  return 'npm';
}

// package.json scripts 확인
function getScripts() {
  try {
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    return pkg.scripts || {};
  } catch {
    return {};
  }
}

// 명령 실행 + 결과 수집
function runStep(name, command) {
  const start = Date.now();
  try {
    const output = execSync(command, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'], timeout: 120000 });
    return {
      name,
      command,
      status: 'pass',
      duration: Date.now() - start,
      output: output.slice(0, 2000) // 출력 2KB 제한
    };
  } catch (e) {
    return {
      name,
      command,
      status: 'fail',
      duration: Date.now() - start,
      error: (e.stderr || e.message || '').slice(0, 2000),
      exitCode: e.status
    };
  }
}

const pm = detectPm();
const scripts = getScripts();
const results = [];

// 1. Lint
if (scripts.lint) {
  results.push(runStep('lint', `${pm} lint`));
} else if (scripts['biome:check'] || scripts['biome']) {
  results.push(runStep('lint', `${pm} biome check`));
} else {
  results.push({ name: 'lint', status: 'skip', reason: 'no lint script' });
}

// 2. Type check
if (scripts['type-check'] || scripts.typecheck) {
  const cmd = scripts['type-check'] ? 'type-check' : 'typecheck';
  results.push(runStep('type-check', `${pm} ${cmd}`));
} else if (fs.existsSync('tsconfig.json')) {
  results.push(runStep('type-check', 'npx tsc --noEmit'));
} else {
  results.push({ name: 'type-check', status: 'skip', reason: 'no tsconfig.json' });
}

// 3. Build
if (scripts.build) {
  results.push(runStep('build', `${pm} build`));
} else {
  results.push({ name: 'build', status: 'skip', reason: 'no build script' });
}

// 4. Test
if (scripts.test) {
  results.push(runStep('test', `${pm} test`));
} else if (scripts['test:unit']) {
  results.push(runStep('test', `${pm} test:unit`));
} else {
  results.push({ name: 'test', status: 'skip', reason: 'no test script' });
}

// 5. Console.log 감사
try {
  const consoleCount = execSync('grep -r "console\\.log" src/ --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" -c 2>/dev/null || echo "0"', { encoding: 'utf8' }).trim();
  const total = consoleCount.split('\n').reduce((sum, line) => {
    const match = line.match(/:(\d+)$/);
    return sum + (match ? parseInt(match[1]) : 0);
  }, 0);
  results.push({
    name: 'console-log-audit',
    status: total > 0 ? 'warn' : 'pass',
    count: total
  });
} catch {
  results.push({ name: 'console-log-audit', status: 'skip', reason: 'grep failed' });
}

// 6. Git status
try {
  const status = execSync('git status --porcelain', { encoding: 'utf8' }).trim();
  const uncommitted = status.split('\n').filter(Boolean).length;
  results.push({
    name: 'git-status',
    status: uncommitted > 0 ? 'warn' : 'pass',
    uncommittedFiles: uncommitted
  });
} catch {
  results.push({ name: 'git-status', status: 'skip', reason: 'not a git repo' });
}

// 요약
const summary = {
  packageManager: pm,
  totalSteps: results.length,
  passed: results.filter(r => r.status === 'pass').length,
  failed: results.filter(r => r.status === 'fail').length,
  skipped: results.filter(r => r.status === 'skip').length,
  warned: results.filter(r => r.status === 'warn').length,
  totalDuration: results.reduce((s, r) => s + (r.duration || 0), 0)
};

console.log(JSON.stringify({ summary, steps: results }, null, 2));
