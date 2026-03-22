#!/usr/bin/env node
/**
 * code-review용 diff 수집 스크립트
 * git diff를 구조화된 JSON으로 출력
 *
 * 사용법: node collect-diff.js [base-branch]
 * 출력: stdout에 JSON
 */
const { execSync } = require('child_process');

const baseBranch = process.argv[2] || 'main';

try {
  // merge-base 찾기
  let mergeBase;
  try {
    mergeBase = execSync(`git merge-base ${baseBranch} HEAD`, { encoding: 'utf8' }).trim();
  } catch {
    // merge-base 못 찾으면 HEAD~1 폴백
    mergeBase = 'HEAD~1';
  }

  // 변경 파일 목록
  const nameStatus = execSync(`git diff --name-status ${mergeBase}...HEAD`, { encoding: 'utf8' }).trim();
  const diffStat = execSync(`git diff --stat ${mergeBase}...HEAD`, { encoding: 'utf8' }).trim();

  const files = nameStatus.split('\n').filter(Boolean).map(line => {
    const [status, ...pathParts] = line.split('\t');
    const filePath = pathParts.join('\t');
    return { status, filePath };
  });

  // 파일별 diff
  const fileDiffs = [];
  for (const file of files) {
    if (file.status === 'D') {
      fileDiffs.push({ ...file, diff: '(deleted)', lines: { added: 0, removed: 0 } });
      continue;
    }
    try {
      const diff = execSync(`git diff ${mergeBase}...HEAD -- "${file.filePath}"`, { encoding: 'utf8' });
      const added = (diff.match(/^\+[^+]/gm) || []).length;
      const removed = (diff.match(/^-[^-]/gm) || []).length;
      fileDiffs.push({ ...file, diff, lines: { added, removed } });
    } catch {
      fileDiffs.push({ ...file, diff: '(error reading diff)', lines: { added: 0, removed: 0 } });
    }
  }

  // 파일 분류
  const classify = (fp) => {
    if (/\.(tsx|jsx)$/.test(fp)) return 'react';
    if (/\.(ts|js)$/.test(fp) && /controller|service|module|guard|interceptor|pipe/.test(fp)) return 'nestjs';
    if (/\.entity\.|\.schema\.|schema\.prisma|\.migration\./.test(fp)) return 'database';
    if (/\.test\.|\.spec\.|\.e2e-/.test(fp)) return 'test';
    if (/\.(ts|js)$/.test(fp)) return 'typescript';
    if (/\.(css|scss|less)$/.test(fp)) return 'style';
    if (/\.(md|json|yaml|yml)$/.test(fp)) return 'config';
    return 'other';
  };

  const result = {
    baseBranch,
    mergeBase,
    totalFiles: files.length,
    totalAdded: fileDiffs.reduce((s, f) => s + f.lines.added, 0),
    totalRemoved: fileDiffs.reduce((s, f) => s + f.lines.removed, 0),
    categories: {},
    files: fileDiffs.map(f => ({
      ...f,
      category: classify(f.filePath)
    }))
  };

  // 카테고리별 집계
  for (const f of result.files) {
    if (!result.categories[f.category]) result.categories[f.category] = 0;
    result.categories[f.category]++;
  }

  console.log(JSON.stringify(result, null, 2));
} catch (e) {
  console.error(JSON.stringify({ error: e.message }));
  process.exit(1);
}
