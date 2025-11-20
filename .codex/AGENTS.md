This AGENTS file defines how Codex should behave in this repo.

Scope: the entire repository.

High‑level goals
- Follow the same coding and testing rules as defined for Cursor in `.cursor/rules/xia.mdc`.
- Prefer small, focused changes; keep functions short (around 20–30 lines) and files single‑responsibility.
- Respect the existing layered architecture: models → services → UI (screens/widgets) → platform glue.

Code style (Dart/Flutter)
- Naming: PascalCase for classes/enums, camelCase for methods/variables, UPPER_SNAKE_CASE for constants, snake_case for file names.
- Imports ordered as: Dart SDK, Flutter, third‑party packages, then project‑local (relative) imports.
- Use 2‑space indentation and keep lines reasonably short (about 100–120 chars).
- Break complex widgets into `_buildXxx` helpers in the same file instead of very large `build()` bodies.

Error handling and logging
- Wrap async calls that can fail in `try/catch`, log errors via the central `Logger` utility where available.
- Never swallow errors silently; either rethrow or surface a clear, user‑friendly state to the UI layer.

Testing
- Keep or add tests for core business logic (RAG, storage, networking, games) in `test/` mirroring `lib/` structure.
- When modifying non‑trivial service logic, prefer to adjust or extend existing tests instead of removing them.
- For new screens, add at least a lightweight widget smoke test that verifies they build and show key UI elements.

AI‑assistant specific rules
- Do not introduce new AI‑tool specific config or metadata files unless explicitly requested.
- You may delete or simplify legacy AI‑assistant docs (e.g., Kiro, Copilot) after their key ideas have been folded into this AGENTS file.
- When in doubt, follow the constraints and style described in `.cursor/rules/xia.mdc` as the source of truth.

Project structure and file creation
- Do not create new top‑level folders (e.g. extra `lib2/`, `src/`, `playground/`) without an explicit user request.
- Place new Dart files only under existing layers: `lib/models`, `lib/services`, `lib/screens`, `lib/widgets`, `lib/config`, `lib/utils`.
- Every new file must be referenced somewhere (imported and used); avoid orphan files or unused stubs.
- Do not create alternative copies of the same module (e.g. `*_new.dart`, `*_fixed.dart`, `*_backup.dart`); refactor existing files in place.
- Never touch generated or external folders (`build/`, `.dart_tool/`, `node_modules/`, platform projects) unless the user explicitly asks.

Flutter‑specific best practices
- Keep business logic in services/models; UI (screens/widgets) should focus on rendering and simple state wiring.
- Prefer composition over very large widgets: split big UIs into smaller widgets and `_buildXxx` helpers.
- Avoid global mutable state; prefer dependency injection or passing objects down the tree.
- Keep async work out of `build()`; do it in `initState`/callbacks/services and expose results via state.
- When adding dependencies in `pubspec.yaml`, do so only if necessary and consistent with the existing stack.

Refactors and migrations
- When changing behavior, prefer incremental refactors over introducing parallel “old/new” service implementations.
- Do not rename or move files in ways that break the existing project structure unless the user requests a larger refactor.
- Remove dead code instead of leaving commented‑out blocks or unused functions/classes.
- If a concept already exists (e.g. a model or service), extend or reuse it instead of creating a second type with the same meaning.

Security and configuration
- Do not hard‑code API keys, secrets, or tokens into source files; use existing config mechanisms instead (see `lib/config/api_config.dart`).
- Treat all network, file, and database calls as fallible: add error handling and logging around them.
- Avoid adding new configuration files unless they clearly integrate with the current config approach.

Testing and safety nets
- When you change non‑trivial logic in `lib/services` or `lib/models`, update or add tests under `test/` that exercise that behavior.
- Prefer strengthening existing tests (e.g. `rag_service_test.dart`, `knowledge_blindbox_test.dart`) instead of duplicating similar test cases in new files.
- Do not add ad‑hoc test entrypoints under `lib/` (no “test harness” screens or scripts) unless explicitly required.

What not to do (AI‑specific)
- Do not generate speculative files “just in case”; every new artifact should be justified by the current task.
- Do not introduce new build tools, CI configs, or formatting setups without a clear user request.
- Do not downgrade or remove existing safeguards (null checks, error handling, logging, tests) when editing code.

Game‑specific guidelines
- Game logic belongs in `lib/services` (e.g. `BookFilingGameService`, `FarmGameService`) and `lib/models` (task/state/asset models); game screens should stay thin and reactive.
- Use coarse‑grained timers (`Timer.periodic`) for minigame loops, and always cancel timers in `dispose()` of the owning widget.
- Minigame screens should follow the same visual style as the rest of the app: educational‑first, simple layouts, gentle animations, limited visual noise.
- New games should follow the existing pattern: define a `GameDefinition`, add a `GameEntryCard` in the chat screen, create a dedicated service + models + screen + tests.
- Each game must have at least: (1) a unit test for its core service logic, and (2) a widget smoke test for its main screen.

