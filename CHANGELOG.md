# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.3] - 2026-08-19

### Fixed
- The full-page library layout now links `layout.css` (left-nav) and `picker.css`
  directly rather than the Sprockets `application.css` manifest, which does not
  bundle `require_tree` under Propshaft — the default asset pipeline in modern
  Rails. On Propshaft hosts the `/media` workspace rendered unstyled.

## [1.1.2] - 2026-08-19

### Changed
- The default admin predicate now recognises both the `admin?` **and**
  `is_admin?` conventions (and returns non-admin for `nil`) instead of assuming
  `admin?`. A host whose user model uses `is_admin?` no longer needs to set
  `config.admin` just to avoid a `NoMethodError` from the role-gated library nav.
  Any other scheme remains fully configurable via `config.admin`.

## [1.1.1] - 2026-08-19

### Fixed
- The picker now hands host URL fields (via `media_picker_field`, e.g. an
  `og:image`) an **absolute, public** Active Storage URL (honoring
  `config.url_type`) instead of the relative, owner-gated `/…/assets/:id` engine
  route. Since 1.0.0 that route was not fetchable by external crawlers, silently
  breaking og:image, social cards, and image SEO. In-admin grid thumbnails keep
  using the gated route, and owner-scoped access is unchanged.

## [1.1.0] - 2026-08-18

### Added
- **Full-page library navigation.** At the engine mount point (`/media`) the
  library now renders a role-gated vertical left-nav in a 30/70 split — a proper
  browsing/management workspace — while the picker modal stays lean for everyday
  "pick and go." Nav entries are built from the same admin gate that guards the
  controllers, so a link is never shown that the controller would `403`.
- **Category tabs in the picker modal.** The modal exposes Images / Legacy /
  Static / Cloud / Community tabs (Legacy is admin-only), each loading its
  category into the picker Turbo Frame.
- **Field-aware type enforcement.** A host field's accepted content types now
  flow (`media_picker_field`/`media_attach_field` → `picker_path(accept:)` →
  frame) into the picker. Assets whose type does not match are rendered
  non-selectable, and uploads of a disallowed type are rejected client-side and
  re-validated server-side (422). Falls back to the configured global allowlist
  when a field declares nothing, and never widens past it.

### Notes
- Static/Cloud assets have no Active Storage `signed_id`; they are pickable into
  URL fields but cannot be attached to `has_one_attached` fields, and selecting
  one never disturbs an existing attachment.

## [1.0.0] - 2026-08-17

### Added
- A stable, documented public release of the mountable Rails media-library
  engine, including private-by-default owner access, optional community sharing,
  administrator imports, and tenant-aware scopes.
- Browsable library and separate host-configured Static Assets pages at the
  engine mount point.
- A headless Chrome system test covering picker open, existing-image selection,
  upload, and Escape-to-close behavior.
- Settings-gated PDF uploads and selection. PDFs are disabled by default,
  rendered as document tiles, and served only as protected attachments.
- CI coverage for Ruby 3.2/Rails 7.1 and Ruby 3.4/Rails 8.1, plus contributor,
  security, and release documentation.

### Security
- Trusted RubyGems publishing through the tag-triggered GitHub OIDC workflow;
  the required publisher configuration is documented in `docs/RELEASING.md`.

## [0.2.0] - 2026-08-17

### Added
- Owner-scoped media records with private-by-default uploads and optional
  community sharing.
- Host `current_user` and `current_user.admin?` conventions, configurable for
  applications with a different authentication model.
- Authorization-aware original and thumbnail delivery routes.
- A tested Rails compatibility range through the 8.x series.

### Security
- Validate detected upload MIME types, require the declared type to match, and
  enforce a configurable size limit.
- Deliver SVG originals as attachments instead of inline documents.
- Add configurable asset and legacy-blob tenant scopes; legacy blobs are denied
  by default until explicitly scoped by the host.

## [0.1.1] - 2026-08-17

### Added
- A self-contained SQLite dummy app and test suite; contributors and CI no
  longer need PostgreSQL.
- CI coverage for RuboCop, the full RSpec suite, gem building, and package
  validation.
- SVG upload coverage. `image/svg+xml` remains part of the default upload
  allowlist.

### Changed
- The dummy app and installation guide now mount the browsable library at
  `/venus_media_library`; the engine root at that URL renders the image grid.
- `allowed_content_types` now strictly controls uploads instead of implicitly
  permitting every `image/*` MIME type.
- JSON pagination is capped at 100 images per page.

## [0.1.0] - 2026-08-15

### Added
- Mountable, isolated Rails engine namespaced under `VenusMediaLibrary`.
- `VenusMediaLibrary::ImagesController` — `index` (HTML grid + JSON) listing `image/*`
  Active Storage blobs newest-first with simple pagination, and `create` for
  uploads via `ActiveStorage::Blob.create_and_upload!` (storage-agnostic).
- `VenusMediaLibrary::PickersController` — Turbo Frame picker body for a target field.
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
  service via `VenusMediaLibrary.configure`.
- Dummy app + RSpec request, model, and helper specs.
