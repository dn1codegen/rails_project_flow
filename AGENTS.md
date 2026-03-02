# AGENTS.md

Guidance for coding agents working in this repository.
This project is a Rails 8 app using Ruby 3.4, SQLite, Minitest, Hotwire, and Importmap.

## Priority Order

1. Follow explicit user instructions.
2. Follow this AGENTS.md.
3. Follow existing code patterns in the touched files.
4. Keep changes minimal, reversible, and well-tested.

## Repository Facts

- Ruby version: `3.4.8` (`.ruby-version`).
- Rails version: `~> 8.1.2` (`Gemfile`).
- Test framework: Minitest (`test/`, `test/test_helper.rb`).
- Linting: RuboCop via `rubocop-rails-omakase`.
- Security checks: Brakeman, bundler-audit, importmap audit.
- JS toolchain: Importmap + Stimulus (no Node build required by default).

## Setup And Local Development

- Initial setup: `bin/setup`
- Setup without starting server: `bin/setup --skip-server`
- Start dev server: `bin/dev`
- Alternative server start: `bin/rails server`
- Prepare DB: `bin/rails db:prepare`
- Reset DB: `bin/rails db:reset`
- Clear logs/tmp: `bin/rails log:clear tmp:clear`

## Build, Lint, Test, And CI Commands

Use `bin/...` wrappers instead of raw gem executables.

### Full CI-equivalent run

- Preferred: `bin/ci`
- CI steps are defined in `config/ci.rb`.

### Lint and static analysis

- Ruby style: `bin/rubocop`
- Ruby style (GitHub formatter): `bin/rubocop -f github`
- Brakeman: `bin/brakeman --no-pager`
- Brakeman strict CI mode:
  `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- Bundler audit: `bin/bundler-audit`
- Importmap audit: `bin/importmap audit`

### Tests

- Run full test suite: `bin/rails test`
- CI test command: `bin/rails db:test:prepare test`
- Prepare test DB only: `bin/rails db:test:prepare`
- Run system tests: `bin/rails test:system`
- CI system test command: `bin/rails db:test:prepare test:system`

### Run a single test (important)

- Single test file:
  `bin/rails test test/models/user_test.rb`
- Single test by line number:
  `bin/rails test test/models/user_test.rb:42`
- Single test by test name pattern:
  `bin/rails test -n test_valid_user`
- Single system test file:
  `bin/rails test:system test/system/users_test.rb`
- Single system test by line:
  `bin/rails test:system test/system/users_test.rb:15`

### Optional build/release tasks

- Precompile assets: `bin/rails assets:precompile`
- Seed test DB as done in CI helper: `RAILS_ENV=test bin/rails db:seed:replant`

## Code Style Guidelines

This project inherits `rubocop-rails-omakase` defaults via `.rubocop.yml`.
When uncertain, write code that passes `bin/rubocop` with no overrides.

### Ruby and Rails style

- Use 2-space indentation, no tabs.
- Keep methods small and intention-revealing.
- Prefer clear guard clauses over deep nesting.
- Prefer expressive predicate method names ending in `?`.
- Use `!` suffix only for dangerous/bang variants.
- Keep controllers thin; move business logic to models/services as complexity grows.
- Prefer framework conventions over custom metaprogramming.
- Avoid introducing new dependencies unless necessary.

### Imports, requires, and load behavior

- Follow Rails autoloading and naming conventions to avoid manual `require`.
- Put explicit `require` usage in boot/config files, not app classes, unless unavoidable.
- In JS, use ES module imports as in existing Stimulus files.
- Keep import paths consistent with Importmap conventions.

### Formatting and structure

- One class/module per file, matching path and constant name.
- File names: `snake_case.rb`; class/module names: `CamelCase`.
- Methods/variables: `snake_case`; constants: `SCREAMING_SNAKE_CASE`.
- Keep line length and layout RuboCop-compliant.
- Avoid commented-out code and dead branches.

### Types and data handling

- There is no static type checker configured; rely on clear interfaces.
- Validate and normalize inputs at boundaries (controllers/jobs/services).
- Use Strong Parameters in controllers for user input.
- Prefer explicit conversions (`to_i`, `to_s`, etc.) when reading untrusted values.

### Error handling

- Fail fast on invalid state; do not silently swallow exceptions.
- Rescue only specific exceptions you can handle meaningfully.
- Keep rescue scope tight; avoid broad `rescue StandardError` in core logic.
- In jobs, use `retry_on`/`discard_on` patterns when appropriate.
- For multi-write operations, use transactions to preserve consistency.

### Database and Active Record

- Put schema-changing work in migrations, not runtime code.
- Prefer query scopes/class methods over repeated ad-hoc query fragments.
- Avoid N+1 queries in controller/view paths.
- Keep callbacks minimal; prefer explicit domain methods for complex flows.

### Views, frontend, and Hotwire

- Prefer server-rendered Rails patterns and progressive enhancement.
- Use Stimulus controllers for small, focused client behavior.
- Keep JS controllers single-purpose and DOM-driven.
- Do not introduce a Node-based bundling step unless requested.

### Testing conventions

- Add or update tests for behavior changes.
- Keep tests deterministic and isolated.
- Prefer the smallest test scope that proves the behavior.
- Use fixtures already configured in `test/test_helper.rb` when practical.
- For bug fixes, add a regression test that fails before the fix.

## Agent Workflow Expectations

- Before finishing, run targeted tests for touched areas at minimum.
- For broad/refactoring changes, run `bin/ci` when feasible.
- Run `bin/rubocop` for Ruby edits.
- If you cannot run a command locally, state what was not run and why.
- Keep diffs focused; avoid unrelated cleanup.

## Cursor/Copilot Rules

- No `.cursorrules` file was found.
- No files were found under `.cursor/rules/`.
- No `.github/copilot-instructions.md` file was found.
- If these rule files are added later, treat them as additional constraints.

## Notes For Future Updates

- If tooling changes, update command examples first.
- If RuboCop rules are customized, document project-specific deviations here.
- If RSpec or other frameworks are added, include equivalent single-test commands.
