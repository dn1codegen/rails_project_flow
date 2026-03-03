# Repository Guidelines

## Project Structure & Module Organization
This is a Rails 8.1 app (Ruby 3.4, SQLite) focused on project publishing and change tracking.
- `app/`: MVC code (`models/`, `controllers/`, `views/`), jobs, mailers, and Hotwire behavior.
- `app/javascript/controllers/`: Stimulus controllers loaded through Importmap.
- `config/`: environment setup, routes, and CI definition (`config/ci.rb`).
- `db/`: schema, migrations, and seeds.
- `test/`: Minitest suites (`models/`, `controllers/`, `system/`) and fixtures.
- `bin/`: project command wrappers; prefer these over raw gem executables.

## Build, Test, and Development Commands
- `bin/setup --skip-server`: install gems, prepare database, skip boot.
- `bin/dev`: start local development processes.
- `bin/rails db:prepare`: create/migrate DB for current environment.
- `bin/rails test`: run all tests.
- `bin/rails test test/models/user_test.rb:42`: run one test at a specific line.
- `bin/rubocop`: run style/lint checks.
- `bin/brakeman --no-pager`, `bin/bundler-audit`, `bin/importmap audit`: security checks.
- `bin/ci`: CI-equivalent local run.

## Coding Style & Naming Conventions
Use Rails conventions and keep code simple and reversible.
- Indentation: 2 spaces, no tabs.
- Ruby names: `snake_case` methods/variables, `CamelCase` classes/modules.
- File naming: `snake_case.rb`, one class/module per file.
- Keep controllers thin; move nontrivial business logic to models/services.
- Follow `.rubocop.yml` (`rubocop-rails-omakase`) and avoid adding dependencies unless necessary.

## Testing Guidelines
Use Minitest and add tests for every behavior change.
- Prefer small, focused tests near the changed code.
- Add regression tests for bug fixes.
- Keep tests deterministic; use fixtures from `test/fixtures` where practical.
- For UI flows, use system tests: `bin/rails test:system`.

## Commit & Pull Request Guidelines
History currently includes only an initial commit, so use a clear convention going forward.
- Commit messages: imperative, concise, scoped (example: `Add validation for project ownership`).
- PRs should include: summary of behavior changes, why the change is needed, test commands run, and screenshots/GIFs for UI updates.
- Keep PRs focused; avoid mixing refactors with feature work.

## Security & Configuration Tips
- Do not commit secrets; use Rails credentials/environment variables.
- Run security tooling before merge (`brakeman`, `bundler-audit`, `importmap audit`).
