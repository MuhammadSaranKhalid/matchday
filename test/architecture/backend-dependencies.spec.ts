import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { describe, expect, it } from 'vitest';

const repositoryRoot = process.cwd();
const backendRoots = ['apps', 'libs'];

function sourceFiles(): string[] {
  const files: string[] = [];

  function visit(path: string): void {
    if (!existsSync(path)) return;

    for (const entry of readdirSync(path)) {
      const entryPath = join(path, entry);
      if (statSync(entryPath).isDirectory()) {
        visit(entryPath);
      } else if (entryPath.endsWith('.ts')) {
        files.push(entryPath);
      }
    }
  }

  for (const root of backendRoots) visit(join(repositoryRoot, root));
  return files;
}

function importsIn(path: string): string[] {
  const contents = readFileSync(path, 'utf8');
  return [...contents.matchAll(/(?:from\s+|import\s*)['"]([^'"]+)['"]/g)]
    .map((match) => match[1])
    .filter((value): value is string => value !== undefined);
}

describe('backend dependency direction', () => {
  it('keeps domain code independent of frameworks and outer layers', () => {
    const forbidden = [
      '@nestjs/',
      'redis',
      'postgres',
      'pg',
      'bullmq',
      'socket.io',
      '@supabase/',
      '/infrastructure/',
      '/presentation/',
    ];
    const violations = sourceFiles()
      .filter((path) => path.split(sep).includes('domain'))
      .flatMap((path) =>
        importsIn(path)
          .filter((specifier) => forbidden.some((value) => specifier.includes(value)))
          .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
      );

    expect(violations).toEqual([]);
  });

  it('keeps application code independent of infrastructure and presentation', () => {
    const violations = sourceFiles()
      .filter((path) => path.split(sep).includes('application'))
      .flatMap((path) =>
        importsIn(path)
          .filter(
            (specifier) =>
              specifier.includes('/infrastructure/') ||
              specifier.includes('/presentation/'),
          )
          .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
      );

    expect(violations).toEqual([]);
  });

  it('does not create application-wide dumping-ground directories', () => {
    const forbiddenNames = new Set([
      'controllers',
      'services',
      'repositories',
      'common',
      'utils',
      'helpers',
    ]);
    const violations: string[] = [];

    function visit(path: string): void {
      if (!existsSync(path)) return;
      for (const entry of readdirSync(path)) {
        const entryPath = join(path, entry);
        if (!statSync(entryPath).isDirectory()) continue;
        if (forbiddenNames.has(entry)) {
          violations.push(relative(repositoryRoot, entryPath));
        }
        visit(entryPath);
      }
    }

    for (const root of backendRoots) visit(join(repositoryRoot, root));
    expect(violations).toEqual([]);
  });

  it('does not import Flutter, website, or legacy media-worker code', () => {
    const violations = sourceFiles().flatMap((path) =>
      importsIn(path)
        .filter(
          (specifier) =>
            specifier.includes('/lib/') ||
            specifier.includes('website/') ||
            specifier.includes('media-worker/'),
        )
        .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
    );

    expect(violations).toEqual([]);
  });

  it('defines API and worker projects in the Nest workspace', () => {
    const nestCliPath = join(repositoryRoot, 'nest-cli.json');
    expect(existsSync(nestCliPath), 'nest-cli.json must exist').toBe(true);

    const nestCli = JSON.parse(readFileSync(nestCliPath, 'utf8')) as {
      projects?: Record<string, { root?: string; sourceRoot?: string }>;
    };

    expect(nestCli.projects?.api).toMatchObject({
      root: 'apps/api',
      sourceRoot: 'apps/api/src',
    });
    expect(nestCli.projects?.worker).toMatchObject({
      root: 'apps/worker',
      sourceRoot: 'apps/worker/src',
    });
  });
});
