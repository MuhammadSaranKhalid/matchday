import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import ts from 'typescript';
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
  return moduleSpecifiers(contents, path);
}

function moduleSpecifiers(contents: string, path = 'fixture.ts'): string[] {
  const source = ts.createSourceFile(path, contents, ts.ScriptTarget.Latest, true);
  const specifiers: string[] = [];

  function visit(node: ts.Node): void {
    if (
      (ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) &&
      node.moduleSpecifier !== undefined &&
      ts.isStringLiteral(node.moduleSpecifier)
    ) {
      specifiers.push(node.moduleSpecifier.text);
    }
    if (
      ts.isCallExpression(node) &&
      node.expression.kind === ts.SyntaxKind.ImportKeyword &&
      node.arguments.length === 1 &&
      ts.isStringLiteral(node.arguments[0])
    ) {
      specifiers.push(node.arguments[0].text);
    }
    ts.forEachChild(node, visit);
  }

  visit(source);
  return specifiers;
}

function targetsLayer(specifier: string, layer: string): boolean {
  return new RegExp(`(^|/)${layer}(?:/|\\.|$)`).test(specifier.replaceAll('\\\\', '/'));
}

function targetsSiblingProject(sourcePath: string, specifier: string): boolean {
  if (!specifier.startsWith('.') && !isAbsolute(specifier)) return false;

  const resolvedImport = resolve(dirname(sourcePath), specifier);
  const repositoryRoot = resolve(process.cwd(), '..');
  const forbiddenRoots = [
    join(repositoryRoot, 'app'),
    join(repositoryRoot, 'website'),
    join(repositoryRoot, 'media-worker'),
    join(repositoryRoot, 'supabase', 'functions'),
  ];

  return forbiddenRoots.some(
    (root) => resolvedImport === root || resolvedImport.startsWith(`${root}${sep}`),
  );
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
      'infrastructure',
      'presentation',
    ];
    const violations = sourceFiles()
      .filter((path) => path.split(sep).includes('domain'))
      .flatMap((path) =>
        importsIn(path)
          .filter((specifier) =>
            forbidden.some((value) =>
              ['infrastructure', 'presentation'].includes(value)
                ? targetsLayer(specifier, value)
                : specifier.includes(value),
            ),
          )
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
              targetsLayer(specifier, 'infrastructure') ||
              targetsLayer(specifier, 'presentation'),
          )
          .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
      );

    expect(violations).toEqual([]);
  });

  it('detects exports, dynamic imports, and root-level forbidden layers', () => {
    const specifiers = moduleSpecifiers(`
      export { adapter } from '../infrastructure.js';
      const screen = import('@feature/presentation/screen.js');
    `);

    expect(specifiers).toEqual([
      '../infrastructure.js',
      '@feature/presentation/screen.js',
    ]);
    expect(specifiers.every((value) =>
      targetsLayer(value, 'infrastructure') || targetsLayer(value, 'presentation'),
    )).toBe(true);
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

  it('does not import app, website, media-worker, or Supabase Function code', () => {
    const violations = sourceFiles().flatMap((path) =>
      importsIn(path)
        .filter((specifier) => targetsSiblingProject(path, specifier))
        .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
    );

    expect(violations).toEqual([]);
  });

  it('recognizes relative imports that escape into sibling projects', () => {
    const sourcePath = join(repositoryRoot, 'apps', 'api', 'src', 'fixture.ts');

    expect(targetsSiblingProject(sourcePath, '../../../../app/lib/main.dart')).toBe(true);
    expect(targetsSiblingProject(sourcePath, '../../../../website/src/index.ts')).toBe(true);
    expect(targetsSiblingProject(sourcePath, '../../../../media-worker/src/index.ts')).toBe(true);
    expect(
      targetsSiblingProject(
        sourcePath,
        '../../../../supabase/functions/_shared/example.ts',
      ),
    ).toBe(true);
    expect(targetsSiblingProject(sourcePath, '../../../libs/platform/src/index.ts')).toBe(false);
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
