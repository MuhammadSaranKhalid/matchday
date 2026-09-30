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
    expect(isConcreteInfrastructureImport('@platform/queue/queue-defaults.js')).toBe(false);
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
    const rootsToCheck = [
      join(repositoryRoot, 'libs'),
      join(repositoryRoot, 'libs', 'platform'),
      join(repositoryRoot, 'libs', 'platform', 'src'),
      join(repositoryRoot, 'apps', 'api'),
      join(repositoryRoot, 'apps', 'api', 'src'),
      join(repositoryRoot, 'apps', 'worker'),
      join(repositoryRoot, 'apps', 'worker', 'src'),
    ];
    const violations: string[] = [];

    for (const root of rootsToCheck) {
      if (!existsSync(root)) continue;
      for (const entry of readdirSync(root)) {
        const entryPath = join(root, entry);
        if (!statSync(entryPath).isDirectory()) continue;
        if (forbiddenNames.has(entry)) {
          violations.push(relative(repositoryRoot, entryPath));
        }
      }
    }

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
  const modulesDir = join(repositoryRoot, 'libs', 'modules');
  const moduleRoots: Array<{ name: string; srcRoot: string }> = readdirSync(modulesDir)
    .filter((entry) => statSync(join(modulesDir, entry)).isDirectory())
    .map((name) => ({ name, srcRoot: join(modulesDir, name, 'src') }));

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
        });

      expect(violations).toEqual([]);
    });
  }
});

describe('apps boundary — no deep relative imports into libs/modules/', () => {
  const modulesRoot = join(repositoryRoot, 'libs', 'modules');

  it('apps do not deep-import into libs/modules/ internals', () => {
    const appsRoot = join(repositoryRoot, 'apps');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(appsRoot))
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

describe('platform wiring and lifecycle invariants', () => {
  it('confines process.env access strictly to platform config and test roots', () => {
    const configDir = join(repositoryRoot, 'libs', 'platform', 'src', 'config');
    const violations = sourceFiles()
      .filter((path) => !path.startsWith(configDir))
      .filter((path) => {
        const contents = readFileSync(path, 'utf8');
        return contents.includes('process.env');
      })
      .map((path) => relative(repositoryRoot, path));

    expect(violations).toEqual([]);
  });

  it('platform never imports feature modules', () => {
    const platformRoot = join(repositoryRoot, 'libs', 'platform');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(platformRoot))
      .flatMap((path) => {
        const imports = importsIn(path);
        const forbidden = imports.filter(
          (specifier) =>
            specifier.includes('/modules/') ||
            specifier.startsWith('@modules/') ||
            specifier === '@modules',
        );
        return forbidden.map((specifier) => `${relative(repositoryRoot, path)} -> ${specifier}`);
      });

    expect(violations).toEqual([]);
  });

  it('api-bootstrap does not import pino-http directly', () => {
    const bootstrapPath = join(repositoryRoot, 'apps', 'api', 'src', 'bootstrap', 'api-bootstrap.ts');
    const imports = importsIn(bootstrapPath);
    expect(imports.some((specifier) => specifier === 'pino-http' || specifier.startsWith('pino-http/'))).toBe(false);
  });

  it('apps/worker does not import BullMQ or access queue tokens directly', () => {
    const workerRoot = join(repositoryRoot, 'apps', 'worker');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(workerRoot))
      .flatMap((path) => {
        const contents = readFileSync(path, 'utf8');
        const imports = importsIn(path);
        const hasForbiddenImport = imports.some(
          (specifier) =>
            specifier === '@nestjs/bullmq' ||
            specifier === 'bullmq' ||
            specifier.startsWith('bullmq/'),
        );
        const usesQueueToken = contents.includes('getQueueToken');
        if (hasForbiddenImport || usesQueueToken) {
          return [`${relative(repositoryRoot, path)} (forbidden BullMQ access)`];
        }
        return [];
      });

    expect(violations).toEqual([]);
  });

  it('MediaModule does not export BullModule', () => {
    const mediaModulePath = join(repositoryRoot, 'libs', 'modules', 'media', 'src', 'media.module.ts');
    const contents = readFileSync(mediaModulePath, 'utf8');
    const exportsMatch = /exports:\s*\[([\s\S]*?)\]/.exec(contents);
    expect(exportsMatch?.[1]).not.toContain('BullModule');
  });

  it('WorkerModule does not import HealthModule', () => {
    const workerModulePath = join(repositoryRoot, 'apps', 'worker', 'src', 'worker.module.ts');
    const imports = importsIn(workerModulePath);
    expect(imports.some((specifier) => specifier.includes('health.module'))).toBe(false);
  });

  it('WorkerLifecycleService does not manually call onApplicationShutdown', () => {
    const lifecyclePath = join(repositoryRoot, 'apps', 'worker', 'src', 'lifecycle', 'worker-lifecycle.service.ts');
    const contents = readFileSync(lifecyclePath, 'utf8');
    expect(contents).not.toContain('onApplicationShutdown');
  });

  it('feature controllers do not import TOKEN_VERIFIER or parse Authorization headers manually', () => {
    const modulesRoot = join(repositoryRoot, 'libs', 'modules');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(modulesRoot) && path.endsWith('.controller.ts'))
      .flatMap((path) => {
        const contents = readFileSync(path, 'utf8');
        const imports = importsIn(path);
        const importsTokenVerifier = imports.some((specifier) => specifier.includes('token-verifier'));
        const parsesAuth = contents.includes('authorization') || contents.includes('Bearer');
        if (importsTokenVerifier || parsesAuth) {
          return [`${relative(repositoryRoot, path)} (manual auth plumbing)`];
        }
        return [];
      });

    expect(violations).toEqual([]);
  });
});

describe('media execution and module isolation invariants', () => {
  it('PostsModule does not import BullMQ directly', () => {
    const postsModuleRoot = join(repositoryRoot, 'libs', 'modules', 'posts', 'src');
    const violations = sourceFiles()
      .filter((path) => path.startsWith(postsModuleRoot))
      .flatMap((path) => {
        const imports = importsIn(path);
        const usesBull = imports.some((specifier) => specifier.includes('bullmq'));
        if (usesBull) {
          return [`${relative(repositoryRoot, path)} (depends on BullMQ directly)`];
        }
        return [];
      });

    expect(violations).toEqual([]);
  });

  it('media contracts export ProcessImageJob with schemaVersion 1', () => {
    const contractPath = join(repositoryRoot, 'libs', 'modules', 'media', 'src', 'contracts', 'media-job.contract.ts');
    const contents = readFileSync(contractPath, 'utf8');
    expect(contents).toContain('ProcessImageJob');
    expect(contents).toContain('readonly schemaVersion: 1;');
    expect(contents).toContain('readonly mediaId: string;');
    expect(contents).not.toContain('ProcessImageJobV2');
    expect(contents).not.toContain('generation');
  });
});


