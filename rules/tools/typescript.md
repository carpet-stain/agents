---
paths:
  - "package.json"
  - "**/*.ts"
  - "**/*.tsx"
---

<!-- TypeScript idioms. Canonical source: this repo. Language-level only — never a repo path,
     service name, or branch name. The paths: frontmatter is the gate: Claude Code loads this
     only when a package.json/*.ts/*.tsx file is read, structurally, no prose guard needed.
     Rationale: README.md. -->

> ### GATE
>
> The `paths:` frontmatter is the gate — this file loads only when Claude reads a TypeScript file
> (`package.json`/`*.ts`/`*.tsx`), in any repo. No prose guard needed.

> ### LOCAL-WINS
>
> If this repo has its own TypeScript standards doc (e.g. docs/CODING.md), that doc is
> AUTHORITATIVE: treat this as baseline and prefer the repo's doc on conflict.

> ### COMPOSE — give a repo its own concrete TypeScript doc
>
> Trigger: the human asks to scaffold, OR a TypeScript repo lacks a standards doc and one is
> warranted. PROPOSE, don't create. Steps: (1) read this as baseline; (2) write a repo-local doc
> (e.g. docs/CODING.md) restating these with the repo's concrete nouns — its linter/formatter
> config, package layout, pinned tool versions, framework stance; (3) add to the repo's AGENTS.md
> that docs/CODING.md is authoritative over generic TypeScript conventions (name no personal
> path); (4) after this the repo reads its own doc — don't re-distill.

# TypeScript Conventions

Baseline is [**Effective TypeScript**](https://effectivetypescript.com/) (Vanderkam) for idiom,
with the [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) for
language reference. Idiom essentials: `camelCase` functions/variables, `PascalCase`
types/classes/interfaces, `UPPER_CASE` constants; ESM (`import`/`export`) never CommonJS, relative
imports carry an explicit `.js` extension under `nodenext` module resolution, `import type` for
type-only imports (`verbatimModuleSyntax`); `strict` everywhere — `noImplicitAny`,
`strictNullChecks`, and the rest are contracts, not friction; infer where the compiler already
knows the type, annotate at function boundaries; `unknown` over `any` at untrusted edges, narrowed
before use; template literal types and `as const` over hand-written string unions.

Design stance: structural interfaces defined where consumed, not where implemented — the same
shape as a Go interface or a Python `Protocol`; a class satisfies an interface by matching its
shape, never by declaring `implements` for the caller's benefit. **Discriminated unions** for
domain modeling — a `kind`/`type` tag plus a `switch` the compiler exhaustiveness-checks — over an
optional-field grab bag or a class hierarchy. Composition over inheritance for code sharing.
Exceptions are the error channel: design a small domain error hierarchy (`extends Error`, a
`code`/discriminant field) and translate it at the boundary; don't import `Result`-type ceremony
from Rust/fp-ts — mirrors `python.md`'s exceptions stance, not Go's error-values-everywhere one.

Make the mechanizable parts tooling-enforced: **Node** (LTS, pinned via `.node-version`) as the
runtime, **pnpm** (via Corepack) for install/lockfile/scripts with `pnpm-lock.yaml` as the one
source of truth, **Biome** for lint+format, **`tsc --noEmit`** strict for typecheck, **vitest** for
test, **tsx** to run TypeScript directly in dev. Judgment parts — API design, naming, module
boundaries — stay a matter of review. For the concrete scaffold (`package.json`, `tsconfig.json`,
`biome.json`, CI wiring), see `project-starter-template`'s TypeScript overlay
([#96](https://github.com/carpet-stain/project-starter-template/issues/96)) rather than
re-deriving it here.

## Dependency posture — TypeScript is not stdlib-maximalist

Go's stdlib-first instinct doesn't transfer — Node's stdlib is a runtime API, not an application
toolkit. Idiomatic TypeScript reaches for the community-standard library where the alternative is
hand-rolled boilerplate: `zod` for runtime validation at untrusted edges, `vitest` over a hand-
rolled test runner, a maintained HTTP client over raw `fetch` plumbing once retries/timeouts
matter. Same posture as Python: prefer the boring, widely adopted choice, and keep the usual
skepticism for single-maintainer micro-deps and frameworks pulled in for one call site —
Simplicity First still applies; liberal is not indiscriminate.

## Application structure (layered apps)

TypeScript-concrete realization of `architecture.md`'s layer-boundary principles.

- **Thin entry point** (`src/index.ts` or a framework's route/handler file) parses input, resolves
  config, composes dependencies, renders output — no domain rules or backend quirks.
- **Domain modules hold plain types and functions** — discriminated unions plus the logic that
  operates on them, importing nothing transport- or IO-specific. Validation libraries (`zod`)
  belong at untrusted-data edges, never as the domain model itself.
- **One thin facade module per external dependency**, owned by you, wrapping its client library —
  the same move as Go's one-package-per-dependency and Python's one-facade-per-dependency: tests
  fake your facade, never the third-party API.
- **Interfaces live with their consumers**, structurally, matching this file's design stance;
  adapters import the domain, never each other.
- **A composition root wires it**: a `main()`/app-factory function passing dependencies as plain
  constructor/function arguments — runtime selection at the top, no DI framework, no globals
  discovered at depth.
- **Domain errors translate at the boundary**: transport code maps the domain error hierarchy to
  status codes/exit codes; deeper layers throw domain errors and never speak HTTP.
