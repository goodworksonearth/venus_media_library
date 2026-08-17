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
- `media_attach_field` host helper — **attach mode** for `has_one_attached`
  associations: the picker writes the chosen blob's `signed_id` into a hidden
  field named for the attachment (e.g. `product[cover]`) so Rails attaches it on
  save. The field is disabled until an image is picked, so saving without picking
  never detaches the current file.
- `config.url_type` (`:redirect` default, or `:proxy`) — build image URLs with
  `rails_storage_proxy_url` so images on a private bucket in proxy mode are
  absolute and publicly fetchable (e.g. for an `og:image`).
- `config.authenticate_with` — a proc run in the engine controller's context
  before every action, so the host can gate the picker/upload endpoints (admins
  only). The engine ships open.
- Configurable allowed content types, thumbnail size, per-page count, and storage
  service via `MediaLibrary.configure`.
- Dummy app + RSpec request, model, and helper specs.
