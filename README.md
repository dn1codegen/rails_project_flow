# Project Chronicle

Project Chronicle is a Ruby on Rails 8.1 app for publishing project cards, storing project files/photos, and keeping a timeline of project changes.

## Feature Overview

- Account registration and sign-in (`has_secure_password`)
- User profile editing
- Public project list and project details page
- Owner-only project editing and deletion
- Owner-only history entry creation
- Active Storage uploads:
  - project cover image
  - measurement images
  - example files (images or documents)
  - installation photos
  - images attached to history entries
- Per-file text descriptions for project attachments
- Attachment cleanup tools in edit form (remove cover image, remove selected files)
- Fullscreen image viewer (Stimulus lightbox) with keyboard navigation

## Tech Stack

- Ruby `3.4.8`
- Rails `8.1.x`
- SQLite3
- Hotwire (Turbo + Stimulus) with Importmap
- Active Storage
- Minitest
- RuboCop (`rubocop-rails-omakase`)
- Brakeman, bundler-audit, importmap audit

## Domain Notes

- `Project` belongs to `User`
- `ProjectChange` belongs to `Project`
- `Project` has many attached files and a cover image
- `ProjectAttachmentDescription` links text descriptions to specific Active Storage attachments
- Project title is auto-synced from `product` before validation

## Prerequisites

- Ruby `3.4.8` (see `.ruby-version`)
- Bundler
- SQLite3

## Setup and Run

Install gems and prepare the database:

```bash
bin/setup --skip-server
```

Start development processes:

```bash
bin/dev
```

Alternative (Rails server only):

```bash
bin/rails server
```

Default app URL: `http://localhost:3000`

## Useful Commands

Database:

```bash
bin/rails db:prepare
bin/rails db:reset
bin/rails db:seed
```

Tests:

```bash
bin/rails test
bin/rails test test/models/user_test.rb
bin/rails test test/models/user_test.rb:42
bin/rails test:system
```

Lint and security:

```bash
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
bin/importmap audit
```

CI-equivalent local run:

```bash
bin/ci
```

## Authorization Rules

- Guests can view projects and project history.
- Signed-in users can create projects.
- Only the project owner can edit/delete a project.
- Only the project owner can add history entries for that project.

## Routes Summary

- `root` -> `projects#index`
- `resource :registration` -> sign up
- `resource :session` -> sign in / sign out
- `resource :profile` -> current user profile
- `resources :projects` -> project CRUD
- `resources :project_changes, only: :create` nested under projects

## Docker

Build image:

```bash
docker build -t codex_2 .
```

Run container:

```bash
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<your_master_key> --name codex_2 codex_2
```

## Notes

- Prefer `bin/...` wrappers over direct gem executables.
- Local file uploads use Active Storage defaults for the current environment.
