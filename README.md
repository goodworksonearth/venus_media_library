# Media Library

A mountable Rails engine that turns **Active Storage** into a browsable media library with an **image picker**.

Content editors get a modal that lists every image already in Active Storage and lets them upload new ones. Drop `media_picker_field` next to any URL field (for example an `og:image` field) so editors *select* an image instead of typing a path.

It is **storage-agnostic**: it uses whatever Active Storage service the host app configures — local Disk in development, Amazon S3 (or GCS, Azure, ...) in production. The engine never talks to a storage backend directly.

- Namespaced under `VenusMediaLibrary::` (isolated engine)
- Lists `ActiveStorage::Blob` records with an `image/*` content type, newest first
- HTML thumbnail grid **and** a JSON API
- Upload via `ActiveStorage::Blob.create_and_upload!`
- A modal picker (Turbo Frame + dependency-free vanilla JS)
- One host helper: `media_picker_field`

## Installation

Add it to the host app's `Gemfile`:

```ruby
gem "venus_media_library"
```

Then:

```bash
bundle install
```

Active Storage must be installed in the host app (`bin/rails active_storage:install && bin/rails db:migrate`).

## Mount the engine

In the host app's `config/routes.rb`:

```ruby
mount VenusMediaLibrary::Engine, at: "/media"
```

Include the picker JavaScript once in your layout (Propshaft/Sprockets):

```erb
<%= javascript_include_tag "venus_media_library/venus_media_library", defer: true %>
```

(Using importmap? `pin "venus_media_library", to: "venus_media_library/venus_media_library.js"` and `import "venus_media_library"`.)

The picker styles are shipped as `venus_media_library/application.css`; require them or add your own — every class is namespaced under `.ml-*`.

## Usage

Replace a plain URL text box with the picker in any form:

```erb
<%= form_with model: @page do |f| %>
  <%= media_picker_field f, :og_image %>
<% end %>
```

That renders the text input you already had, plus a **"Choose from library"** button. Clicking it opens the modal; selecting an image writes its URL into the input (and its Active Storage `signed_id` into a hidden `og_image_signed_id` companion field), then closes the modal. Editors can also upload a new image from inside the modal.

### Attach mode — `media_attach_field` (for `has_one_attached`)

Use `media_attach_field` when the field is an **Active Storage attachment**
(`has_one_attached`) rather than a URL column. Instead of a URL, the picker writes
the chosen blob's `signed_id` into a hidden field **named for the attachment**, so
Rails attaches that blob on save:

```erb
<%= form_with model: @product do |f| %>
  <%= media_attach_field f, :cover %>
<% end %>
```

This renders a read-only preview input (not submitted) plus the "Choose from
library" button, and a hidden `product[cover]` field carrying the signed id. That
hidden field ships **disabled** and is enabled by the picker only once an image is
chosen — so submitting the form without picking never detaches the current file
(an empty value for a `has_one_attached` would otherwise purge it). `has_one_attached`
accepts a `signed_id` natively, so no controller changes are needed beyond
permitting the attachment param (e.g. `params.permit(:cover)`).

### `media_picker_field` options

| Option | Default | Description |
| --- | --- | --- |
| `:label` | `"Choose from library"` | Button label |
| `:placeholder` | `nil` | Placeholder for the text input |
| `:signed_id_field` | `"<field>_signed_id"` | Name of the hidden signed-id input; pass `false` to omit |
| `:input_html` | `{}` | Extra HTML options merged into the text input |
| `:class` | `"ml-field"` | Wrapper CSS class |

### Endpoints

Mounted at your chosen path (examples assume `/media`):

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/media/images` | HTML thumbnail grid (also `.json`) |
| `GET` | `/media/images.json` | `{ images: [...], page:, has_more:, total: }` |
| `POST` | `/media/images` | Upload a file (param `file`); returns the image JSON |
| `GET` | `/media/picker?target=<input_id>` | Turbo Frame body for the modal |

Each image payload includes `id`, `signed_id`, `filename`, `content_type`, `byte_size`, `url`, and `thumb_url`.

## Configuration

In an initializer (e.g. `config/initializers/venus_media_library.rb`):

```ruby
VenusMediaLibrary.configure do |config|
  # Content types accepted by the uploader (any image/* is always allowed in the grid).
  config.allowed_content_types = %w[image/png image/jpeg image/webp image/gif image/svg+xml]

  # [width, height] for the grid thumbnail variant.
  config.thumbnail_size = [300, 300]

  # Images per page in the index / picker.
  config.per_page = 40

  # Which Active Storage service to store uploads on. nil = the host app's
  # default service (Disk in dev, S3 in prod, etc.).
  config.storage_service = nil

  # How image URLs are built. :redirect (default) uses rails_blob_url; :proxy
  # uses rails_storage_proxy_url so images on a PRIVATE bucket in proxy mode are
  # absolute and publicly fetchable by crawlers (e.g. for an og:image).
  config.url_type = :redirect

  # Optional access gate. A proc run in the engine controller's context before
  # every action, so it can use host helpers (current_user, redirect_to, head,
  # main_app). Left nil the engine is open — set it to restrict the picker and
  # upload endpoints to admins:
  #
  #   config.authenticate_with = lambda do
  #     redirect_to main_app.root_path unless current_user&.admin?
  #   end
  config.authenticate_with = nil
end
```

Every action of the mounted engine (list, upload, picker frame) runs
`authenticate_with`, so gating it there is enough to keep uploads and the image
list off-limits to non-admins.

Thumbnails use Active Storage variants, which require `image_processing` (a runtime dependency of this gem) plus libvips or ImageMagick on the host.

## Development

The engine ships with a dummy app under `spec/dummy` (Active Storage configured with the Disk service, engine mounted at `/media`).

```bash
bundle install
cd spec/dummy && bin/rails db:prepare && cd -   # set up Active Storage tables
bundle exec rspec                               # run the test suite
```

## Publishing

This gem is built to be published to RubyGems under a **Good Works On Earth** name.

```bash
gem build venus_media_library.gemspec        # produces venus_media_library-<version>.gem
gem push venus_media_library-<version>.gem   # publish to RubyGems
```

`gem push` requires RubyGems credentials (and 2FA/OTP if enabled) — **the gem owner enters these**; they are not stored in the repo. Bump `VenusMediaLibrary::VERSION` in `lib/venus_media_library/version.rb` before each release.

## License

MIT — see [MIT-LICENSE](MIT-LICENSE).
