# Agent: tdd-refactor

## Trigger

`/tdd-refactor <path/to/file.dart>` — "refactorizar con TDD", "aplicar TDD a este provider/widget"

## Input contract

The user passes a single file path. The agent reads that file plus what it needs to understand
the full picture: the feature folder it belongs to (`data/`/`providers/`/`models/`/`widgets/`),
related providers it depends on, and any existing test.

---

## Phase 0 — Orient

1. Read the target file completely.
2. Locate and read: the feature's `data/`/`providers/`/`models/` siblings, any shared widget from
   `shared/widgets/` it uses, existing `_test.dart` if any (if one exists, go directly to Phase 2).
3. Identify the **public contract** that must NOT change: exported provider/widget name and
   parameters, the route it renders on (if a screen), the shape of data it reads/writes.
4. Output a brief orientation table:

```
FILE:        lib/features/services/providers/services_provider.dart
TYPE:        Riverpod AsyncNotifier
DEPS:        ApiClient, ServiceModel
SPEC:        missing → will create
CONTRACT:    acceptService(referenceId), completeService(referenceId)
VIOLATIONS:  will diagnose in Phase 1
```

## Phase 1 — Diagnosis

Scan for violations of this project's rules (`.claude/rules/flutter-architecture.md`,
`.claude/rules/auth.md`): fetching logic inside a widget instead of a provider, hardcoded
colors/spacing, missing 409-conflict handling on a state-changing action, `id` interno used where
`referenceId` should be, missing loading/error/empty states.

## Phase 2 — Characterization Test

If no test exists, create `<file>_test.dart` capturing CURRENT behavior exactly (including known
bugs, documented with `// BUG: ...`). Mock the network boundary, never the unit under test. AAA
pattern, Spanish test names describing behavior. Run `flutter test <file>` and confirm green
against the unmodified code.

## Phase 3 — Refactoring Plan

Present the ordered plan BEFORE touching anything. Each step: what changes, why (which rule/
violation it fixes), contract impact (must be `NONE`).

## Phase 4 — Execute (one step at a time)

Make the change → run the test → report `✓ Step N complete` or diagnose a failure before
continuing. Never proceed with a red test.

## Phase 5 — Final Spec Update

Clean up characterization-test comments that documented now-fixed bugs, verify mocks still match
the refactored dependencies, run the full test file once more, output a short summary (files
created/modified, tests written, contract unchanged confirmation).

---

## Hard constraints — never violate

- Never change: exported provider/widget signature, route path, the shape of data a provider
  exposes to its consumers.
- Never move business logic into a widget — it belongs in `providers/`/`data/`.
- Never skip running tests between steps.
- Never use `dynamic` in new code without a comment justifying it.
- Never call the backend URL directly from a widget — always through `core/api_client`.

## Rules

- @../rules/test.md
- @../rules/flutter-architecture.md
