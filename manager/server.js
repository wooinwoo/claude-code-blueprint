import { createServer } from 'http';
import { readFileSync, existsSync, readdirSync, statSync, writeFileSync } from 'fs';
import { join, resolve, basename, dirname } from 'path';
import { execSync, exec } from 'child_process';
import { fileURLToPath } from 'url';
import { homedir, platform } from 'os';

const __dirname = dirname(fileURLToPath(import.meta.url));
const CCB_ROOT = resolve(__dirname, '..');
const PORT = 3850;
const PROFILES = ['react-next', 'nestjs', 'fullstack', 'java-web', 'designer', 'planner'];

// ============================================================
// Git / Project Detection
// ============================================================

function findProjects() {
  const projects = [];
  const searchPaths = getSearchPaths();

  for (const searchPath of searchPaths) {
    if (!existsSync(searchPath)) continue;
    scanDir(searchPath, projects, 0, 4);
  }
  return projects;
}

function getSearchPaths() {
  const home = homedir();
  const paths = [];
  const os = platform();

  if (os === 'win32') {
    // Windows 드라이브
    for (const drive of ['C', 'D', 'E']) {
      const p = `${drive}:/_project`;
      if (existsSync(p)) paths.push(p);
      const p2 = `${drive}:/Projects`;
      if (existsSync(p2)) paths.push(p2);
    }
    paths.push(join(home, 'Documents'));
    paths.push(join(home, 'Desktop'));

    // WSL 경로 (Windows에서 접근)
    const wslPath = '//wsl$/Ubuntu/home';
    if (existsSync(wslPath)) {
      try {
        const dirs = readdirSync(wslPath);
        for (const d of dirs) paths.push(join(wslPath, d));
      } catch {}
    }
  } else {
    // macOS / Linux
    paths.push(join(home, 'Projects'));
    paths.push(join(home, 'projects'));
    paths.push(join(home, 'dev'));
    paths.push(join(home, 'workspace'));
    paths.push(join(home, 'Documents'));
    paths.push('/opt/projects');
  }

  return paths.filter(p => existsSync(p));
}

function scanDir(dir, results, depth, maxDepth) {
  if (depth > maxDepth) return;
  try {
    const entries = readdirSync(dir);

    // .git 있으면 프로젝트
    if (entries.includes('.git')) {
      const project = getProjectInfo(dir);
      if (project) results.push(project);
      return; // 하위 탐색 중단
    }

    // 하위 디렉토리 탐색
    for (const entry of entries) {
      if (entry.startsWith('.') || entry === 'node_modules' || entry === 'dist' || entry === 'build') continue;
      const fullPath = join(dir, entry);
      try {
        if (statSync(fullPath).isDirectory()) {
          scanDir(fullPath, results, depth + 1, maxDepth);
        }
      } catch {}
    }
  } catch {}
}

function getProjectInfo(dir) {
  try {
    const name = basename(dir);
    const hasClaude = existsSync(join(dir, '.claude'));
    let profile = null;
    let lastUpdate = null;

    const stackFile = join(dir, '.claude', '.ccb-stack');
    if (existsSync(stackFile)) {
      profile = readFileSync(stackFile, 'utf8').trim();
    }

    // git 정보
    let branch = '';
    let status = '';
    let lastCommit = '';
    let remote = '';

    try {
      branch = execSync('git branch --show-current', { cwd: dir, encoding: 'utf8', timeout: 5000 }).trim();
      status = execSync('git status --porcelain', { cwd: dir, encoding: 'utf8', timeout: 5000 }).trim();
      lastCommit = execSync('git log -1 --format="%h %s" 2>/dev/null', { cwd: dir, encoding: 'utf8', timeout: 5000 }).trim();
      remote = execSync('git remote get-url origin 2>/dev/null', { cwd: dir, encoding: 'utf8', timeout: 5000 }).trim();
    } catch {}

    // branches
    let branches = [];
    try {
      const branchList = execSync('git branch --format="%(refname:short)"', { cwd: dir, encoding: 'utf8', timeout: 5000 }).trim();
      branches = branchList.split('\n').filter(Boolean);
    } catch {}

    // package.json
    let packageName = name;
    let tech = [];
    const pkgPath = join(dir, 'package.json');
    if (existsSync(pkgPath)) {
      try {
        const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
        packageName = pkg.name || name;
        const deps = { ...pkg.dependencies, ...pkg.devDependencies };
        if (deps.react) tech.push('React');
        if (deps.next) tech.push('Next.js');
        if (deps['@nestjs/core']) tech.push('NestJS');
        if (deps.vue) tech.push('Vue');
        if (deps.tailwindcss) tech.push('Tailwind');
        if (deps.typescript || deps['@types/node']) tech.push('TypeScript');
      } catch {}
    }

    const uncommitted = status ? status.split('\n').filter(Boolean).length : 0;

    return {
      path: dir,
      name: packageName,
      hasClaude,
      profile,
      branch,
      branches,
      uncommitted,
      lastCommit,
      remote,
      tech
    };
  } catch {
    return null;
  }
}

// ============================================================
// Actions
// ============================================================

function installProfile(projectPath, profile) {
  const os = platform();

  let cmd;
  if (os === 'win32') {
    const ps1 = join(CCB_ROOT, 'setup.ps1');
    cmd = `powershell -File "${ps1}" ${profile} "${projectPath}"`;
  } else {
    const sh = join(CCB_ROOT, 'setup.sh');
    cmd = `bash "${sh}" ${profile} "${projectPath}"`;
  }

  try {
    const output = execSync(cmd, { encoding: 'utf8', timeout: 60000 });
    return { success: true, output };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

function uninstallClaude(projectPath) {
  const claudeDir = join(projectPath, '.claude');
  if (!existsSync(claudeDir)) return { success: false, error: '.claude not found' };

  try {
    execSync(`rm -rf "${claudeDir}"`, { encoding: 'utf8' });
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

function gitCommitPush(projectPath, branch, message) {
  try {
    execSync(`git checkout ${branch}`, { cwd: projectPath, encoding: 'utf8', timeout: 10000 });
    execSync('git add .claude/', { cwd: projectPath, encoding: 'utf8', timeout: 10000 });

    const status = execSync('git status --porcelain .claude/', { cwd: projectPath, encoding: 'utf8' }).trim();
    if (!status) return { success: true, message: 'Nothing to commit' };

    execSync(`git commit -m "${message.replace(/"/g, '\\"')}"`, { cwd: projectPath, encoding: 'utf8', timeout: 10000 });
    execSync(`git push origin ${branch}`, { cwd: projectPath, encoding: 'utf8', timeout: 30000 });
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

function getBranches(projectPath) {
  try {
    const local = execSync('git branch --format="%(refname:short)"', { cwd: projectPath, encoding: 'utf8', timeout: 5000 }).trim().split('\n').filter(Boolean);
    const current = execSync('git branch --show-current', { cwd: projectPath, encoding: 'utf8', timeout: 5000 }).trim();
    return { branches: local, current };
  } catch {
    return { branches: [], current: '' };
  }
}

// ============================================================
// HTTP Server
// ============================================================

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

  // API
  if (url.pathname === '/api/projects') {
    const projects = findProjects();
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(projects));
    return;
  }

  if (url.pathname === '/api/profiles') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(PROFILES));
    return;
  }

  if (url.pathname === '/api/switch-branch' && req.method === 'POST') {
    const body = await getBody(req);
    const { path: projectPath, branch } = JSON.parse(body);
    try {
      // stash if dirty
      const status = execSync('git status --porcelain', { cwd: projectPath, encoding: 'utf8' }).trim();
      if (status) {
        execSync('git stash', { cwd: projectPath, encoding: 'utf8', timeout: 10000 });
      }
      execSync(`git checkout ${branch}`, { cwd: projectPath, encoding: 'utf8', timeout: 10000 });
      if (status) {
        try { execSync('git stash pop', { cwd: projectPath, encoding: 'utf8', timeout: 10000 }); } catch {}
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, branch }));
    } catch (e) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: e.message }));
    }
    return;
  }

  if (url.pathname === '/api/install' && req.method === 'POST') {
    const body = await getBody(req);
    const { path: projectPath, profile } = JSON.parse(body);
    const result = installProfile(projectPath, profile);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
    return;
  }

  if (url.pathname === '/api/uninstall' && req.method === 'POST') {
    const body = await getBody(req);
    const { path: projectPath } = JSON.parse(body);
    const result = uninstallClaude(projectPath);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
    return;
  }

  if (url.pathname === '/api/commit' && req.method === 'POST') {
    const body = await getBody(req);
    const { path: projectPath, branch, message } = JSON.parse(body);
    const result = gitCommitPush(projectPath, branch, message);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
    return;
  }

  if (url.pathname === '/api/branches' && req.method === 'POST') {
    const body = await getBody(req);
    const { path: projectPath } = JSON.parse(body);
    const result = getBranches(projectPath);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(result));
    return;
  }

  if (url.pathname === '/api/update-all' && req.method === 'POST') {
    const projects = findProjects().filter(p => p.profile);
    const results = [];
    for (const p of projects) {
      const r = installProfile(p.path, p.profile);
      results.push({ path: p.path, profile: p.profile, ...r });
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(results));
    return;
  }

  // Static
  if (url.pathname === '/' || url.pathname === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(readFileSync(join(__dirname, 'index.html'), 'utf8'));
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

function getBody(req) {
  return new Promise((resolve) => {
    let body = '';
    req.on('data', c => body += c);
    req.on('end', () => resolve(body));
  });
}

server.listen(PORT, () => {
  console.log(`\n  CCB Manager running at http://localhost:${PORT}\n`);
  console.log(`  CCB Root: ${CCB_ROOT}`);
  console.log(`  Platform: ${platform()}`);
  console.log(`  Scanning for projects...\n`);
});
