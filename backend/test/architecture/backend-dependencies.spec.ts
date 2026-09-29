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

function isConcreteInfrastructureImport(specifier: string): boolean {
  return ['pg', 'ioredis', 'bullmq', '@nestjs/bullmq'].some(
    (dependency) => specifier === dependency || specifier.startsWith(`${dependency}/`),
  );
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
              targetsLayer(specifier, 'presentation') ||
              isConcreteInfrastructureImport(specifier),
          )
          .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`),
      );

    expect(violations).toEqual([]);
  });

  it('rejects concrete persistence and queue packages from inner layers', () => {
    expect(['pg', 'ioredis', 'bullmq', '@nestjs/bullmq'].every(isConcreteInfrastructureImport))
      .toBe(true);
    expect(isConcreteInfrastructureImport('@platform/queue/queue-names.js')).toBe(false);
  });

  it('keeps the PostgreSQL driver inside platform database infrastructure', () => {
    const violations = sourceFiles()
      .filter((path) => !path.includes(join('libs', 'platform', 'src', 'database')))
      .flatMap((path) =>
        importsIn(path)
          .filter((specifier) => specifier === 'pg' || specifier.startsWith('pg/'))
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

describe('module public API boundaries', () => {
  /**
   * Files outside libs/modules/<name>/ may not import a relative path that
   * resolves into that module's src/ tree. They must go through the module's
   * public index (e.g. @modules/posts) instead.
   *
   * Step 2 cleanup target: the violations listed below are pre-approved
   * boundary debts that will be eliminated in the next refactor phase.
   * Remove entries from this list as each is fixed — the list must only shrink.
   */
  const step2Allowlist = new Set([
    // worker.module.ts deep-imports into media internals (Step 2: move to MediaModule API)
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/application/process-image.service.js',
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/application/ports/media-object-storage.js',
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/infrastructure/persistence/postgres-media.repository.js',
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/infrastructure/scratch/scratch-workspace.service.js',
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/infrastructure/image/sharp-image-transformer.js',
    'apps/worker/src/worker.module.ts -> ../../../libs/modules/media/src/media.module.js',
    // posts application services reach into media ports (Step 2: re-export via MediaModule or SharedKernel)
    'libs/modules/posts/src/application/create-post.service.ts -> ../../../media/src/application/ports/media-object-storage.js',
    'libs/modules/posts/src/application/publish-post.service.ts -> ../../../media/src/application/ports/media-object-storage.js',
    'libs/modules/posts/src/application/publish-post.service.ts -> ../../../media/src/domain/media-policy.js',
    'libs/modules/posts/src/posts.module.ts -> ../../media/src/application/ports/media-object-storage.js',
    'libs/modules/posts/src/presentation/http/dto/post-command.dto.ts -> ../../../../../../modules/media/src/domain/media-policy.js',
  ]);

  const moduleRoots: Array<{ name: string; srcRoot: string }> = [
    { name: 'posts', srcRoot: join(repositoryRoot, 'libs', 'modules', 'posts', 'src') },
    { name: 'media', srcRoot: join(repositoryRoot, 'libs', 'modules', 'media', 'src') },
  ];

  for (const { name, srcRoot } of moduleRoots) {
    const moduleDir = join(srcRoot, '..');

    it(`external files do not deep-import into @modules/${name} internals`, () => {
      const violations = sourceFiles()
        .filter((path) => !path.startsWith(moduleDir))
        .flatMap((path) => {
          const dir = dirname(path);
          return importsIn(path)
            .filter((specifier) => {
              if (!specifier.startsWith('.') && !isAbsolute(specifier)) return false;
              const resolved = resolve(dir, specifier);
              return (
                (resolved === srcRoot || resolved.startsWith(`${srcRoot}${sep}`)) &&
                resolved !== join(srcRoot, 'index.ts') &&
                resolved !== join(srcRoot, 'index.js')
              );
            })
            .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`);
        })
        .filter((entry) => !step2Allowlist.has(entry));

      expect(violations).toEqual([]);
    });
  }
});

describe('apps boundary — no deep relative imports into libs/modules/', () => {
  /**
   * apps/* processes are composition roots. They must import business modules
   * through public aliases (@modules/posts, @modules/media), not via relative
   * paths that pierce into libs/modules/<name>/src/** internals.
   *
   * Exception: apps/worker currently has pre-approved deep imports into
   * libs/modules/media (cleaned up in Step 2). This test enforces the rule
   * for apps/api, which must be clean now.
   */
  const modulesRoot = join(repositoryRoot, 'libs', 'modules');

  it('apps/api does not deep-import into libs/modules/ internals', () => {
    const apiRoot = join(repositoryRoot, 'apps', 'api');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(apiRoot))
      .flatMap((path) => {
        const dir = dirname(path);
        return importsIn(path)
          .filter((specifier) => {
            if (!specifier.startsWith('.') && !isAbsolute(specifier)) return false;
            const resolved = resolve(dir, specifier);
            return resolved === modulesRoot || resolved.startsWith(`${modulesRoot}${sep}`);
          })
          .map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`);
      });

    expect(violations).toEqual([]);
  });
});
