# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-08-15

### Added
- Mountable, isolated Rails engine namespaced under `MediaLibrary`.
- `MediaLibrary::ImagesController` — `index` (HTML grid + JSON) listing `image/*`
  Active Storage blobs newest-first with simple pagination, and `create` for
  uploads via `ActiveStorage::Blob.create_and_upload!` (storage-agnostic).
- `MediaLibrary::PickersController` — Turbo Frame picker body for a target field.
- `media_picker_field` host helper (auto-included into host views) that renders a
  URL text input plus a "Choose from library" button and a shared modal shell.
- Dependency-free vanilla JS picker (opens the modal, selects an image, uploads).
- Configurable allowed content types, thumbnail size, per-page count, and storage
  service via `MediaLibrary.configure`.
- Dummy app + RSpec request and helper specs.
