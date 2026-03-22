#!/usr/bin/env node
/**
 * MySQL MCP 서버 실행 래퍼
 * .claude/.env 에서 DATABASE_URL 읽어서 실행합니다.
 *
 * 사용법: .claude/.env 에 DATABASE_URL=mysql://user:pass@host:3306/dbname 설정
 */
const fs = require("fs");
const path = require("path");

// Load .env: 글로벌(~/.claude/.env) → 프로젝트(.claude/.env) 순서
function loadEnv(filePath) {
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, "utf8");
    for (const line of content.split(/\r?\n/)) {
      const match = line.match(/^([^=\s#]+)=(.*)$/);
      if (match) {
        process.env[match[1]] = match[2].trim();
      }
    }
  }
}

const homeDir = process.env.USERPROFILE || process.env.HOME;
loadEnv(path.join(homeDir, ".claude", ".env"));
loadEnv(path.join(__dirname, "..", ".env"));

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error("DATABASE_URL not found in .claude/.env");
  process.exit(1);
}

const { spawn } = require("child_process");
const child = spawn(
  "npx",
  ["-y", "@benborla29/mcp-server-mysql", "--db-url", databaseUrl],
  {
    stdio: "inherit",
    shell: true,
  }
);

child.on("exit", (code) => process.exit(code || 0));
