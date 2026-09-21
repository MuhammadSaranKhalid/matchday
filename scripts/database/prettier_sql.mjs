// Called by format_migrations.py; the Python wrapper verifies PostgreSQL syntax
// and semantics before writing. Do not use the experimental plugin unguarded.
import fs from "node:fs";
import * as prettier from "prettier";
import * as sqlPlugin from "prettier-plugin-sql-cst";

const options = JSON.parse(
  fs.readFileSync(new URL("./sql-format.json", import.meta.url), "utf8"),
);
// Python supplies a pipe. Async reads also handle large migrations on macOS,
// where a synchronous read of the nonblocking pipe can fail with EAGAIN.
process.stdin.setEncoding("utf8");
let source = "";
for await (const chunk of process.stdin) source += chunk;
process.stdout.write(
  await prettier.format(source, { ...options, plugins: [sqlPlugin] }),
);
