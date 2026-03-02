# Project Chronicle

Project Chronicle is a Ruby on Rails 8 application for publishing projects, uploading related files/photos, and tracking project change history over time.

## Core Features

- User registration and authentication (`has_secure_password`)
- User profile management
- Public project feed and project detail pages
- Project ownership rules (only owners can edit a project)
- Project history entries (only owners can add changes)
- File attachments with Active Storage:
  - Measurement images
  - Example files
  - Installation photos

## Tech Stack

- Ruby `3.4.8`
- Rails `8.1.x`
- SQLite3
- Minitest
- Hotwire (Turbo + Stimulus) with Importmap
- Propshaft
- Solid Cache, Solid Queue, Solid Cable

## Prerequisites

- Ruby `3.4.8` (see `.ruby-version`)
- Bundler
- SQLite3

## Local Setup

Install dependencies and prepare the database:

```bash
bin/setup --skip-server
```

Start the app:

```bash
bin/dev
```

Alternative server command:

```bash
bin/rails server
```

The app will usually be available at `http://localhost:3000`.

## Database Commands

```bash
bin/rails db:prepare
bin/rails db:reset
bin/rails log:clear tmp:clear
```

## Test, Lint, and Security

Run full test suite:

```bash
bin/rails test
```

Run a single test file:

```bash
bin/rails test test/models/user_test.rb
```

Run a single test by line:

```bash
bin/rails test test/models/user_test.rb:42
```

Style checks:

```bash
bin/rubocop
```

Security checks:

```bash
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
```

Run CI-equivalent pipeline:

```bash
bin/ci
```

## Application Routes Overview

- `root` -> projects index
- `resource :registration` -> sign up
- `resource :session` -> sign in/sign out
- `resource :profile` -> show/edit/update current user profile
- `resources :projects` -> project CRUD
- `resources :project_changes, only: :create` nested under projects

## Docker (Production-Oriented)

This repository includes a production-focused `Dockerfile`.

Build image:

```bash
docker build -t codex_2 .
```

Run container:

```bash
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<your_master_key> --name codex_2 codex_2
```

## Notes

- `db/seeds.rb` currently contains only the template comment block (no seed data yet).
- Use `bin/...` wrappers rather than raw gem executables for project commands.
