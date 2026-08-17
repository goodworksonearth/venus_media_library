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
mount VenusMediaLibrary::Engine, at: "/venus_media_library"
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

Mounted at your chosen path (examples assume `/venus_media_library`):

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/venus_media_library` | Browsable HTML thumbnail grid |
| `GET` | `/venus_media_library/images` | HTML thumbnail grid (also `.json`) |
| `GET` | `/venus_media_library/images.json` | `{ images: [...], page:, has_more:, total: }` |
| `POST` | `/venus_media_library/images` | Upload a file (param `file`); returns the image JSON |
| `GET` | `/venus_media_library/picker?target=<input_id>` | Turbo Frame body for the modal |

Each image payload includes `id`, `signed_id`, `filename`, `content_type`, `byte_size`, `url`, and `thumb_url`.

## Configuration

In an initializer (e.g. `config/initializers/venus_media_library.rb`):

```ruby
VenusMediaLibrary.configure do |config|
  # Content types accepted by the uploader.
  config.allowed_content_types = %w[image/png image/jpeg image/webp image/gif image/svg+xml]

  # [width, height] for the grid thumbnail variant.
  config.thumbnail_size = [300, 300]

  # Images per page in the index / picker.
  config.per_page = 40

  # Which Active Storage service to store uploads on. nil = the host app's
  # default service (Disk in dev, S3 in prod, etc.).
  config.storage_service = nil

  # Retained for compatibility. Library URLs are authorization-aware engine URLs.
  config.url_type = :redirect

  # Optional access gate. A proc run in the engine controller's context before
  # every action, so it can use host helpers (current_user, redirect_to, head,
  # main_app). Use it for a custom precondition before engine actions:
  #
  #   config.authenticate_with = lambda do
  #     redirect_to main_app.root_path unless current_user&.admin?
  #   end
  config.authenticate_with = nil

  # Ownership defaults to the host application's authentication convention.
  config.current_user = -> { current_user }
  config.admin = ->(user) { user.admin? }
end
```

### Configuration Details

- **`allowed_content_types`** — Restricts uploads to these exact MIME types. The default explicitly includes SVG (`image/svg+xml`).

- **`thumbnail_size`** — Array of `[width, height]` for grid thumbnails. Larger values give better preview quality at the cost of image processing overhead and bandwidth.

- **`per_page`** — Number of images to display per page. Smaller values suit mobile-friendly UIs; larger values reduce pagination clicks. JSON callers can request up to 100 images per page.

- **`storage_service`** — Active Storage service name (e.g. `:amazon`, `:google`). Leave `nil` to use the host app's default, making the engine truly storage-agnostic. Uploads automatically inherit the configured service.

- **`current_user`** — A controller-context callback that returns the signed-in host user. It defaults to `current_user`; every engine endpoint requires it to return a user.

- **`admin`** — A callback that determines whether that user can manage all media. It defaults to `->(user) { user.admin? }`.

- **`url_type`** — Retained for backward-compatible host configuration. Browsing and picker URLs are always protected engine routes, so private uploads are never exposed via an Active Storage signed URL.

- **`authenticate_with`** — A proc that gates access to the engine. Runs before every action in the engine's controller context, so you can call host helpers like `current_user`, `redirect_to`, and `head`. Return nothing to allow, or redirect/deny to block. Example:
  ```ruby
  config.authenticate_with = lambda do
    redirect_to main_app.root_path unless current_user&.admin?
  end
  ```

### Image Processing & Thumbnails

Thumbnails use Active Storage variants, which require two system dependencies:

1. **`image_processing`** gem — Already a runtime dependency of this gem.
2. **Image library** — Either `libvips` (recommended) or ImageMagick on the host server.

On macOS, install via Homebrew:
```bash
brew install vips
```

On Linux (Ubuntu/Debian):
```bash
apt-get install libvips libvips-dev
```

Without these, variant generation fails and thumbnail images won't display.

## Styling & Customization

All picker and library CSS is namespaced under `.ml-*` classes to avoid conflicts with the host app. The engine ships two stylesheets:

- **`venus_media_library/application.css`** — Layout and structure (grid, pagination, forms).
- **`venus_media_library/picker.css`** — Button and interactive styles.

To override styles, require the engine CSS first, then add your own:

```erb
<%= stylesheet_link_tag "venus_media_library/application" %>
<%= stylesheet_link_tag "venus_media_library/picker" %>
<style>
  .ml-grid { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); }
  .ml-tile:hover { border-color: #ff6b6b; }
</style>
```

Or, in your own CSS file:
```css
.ml-grid {
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
}

.ml-btn--primary {
  background: #your-brand-color;
}
```

### CSS Classes Reference

- `.ml-field` — Wrapper for the picker field + button.
- `.ml-field__input` — The text input element.
- `.ml-btn`, `.ml-btn--primary` — Buttons.
- `.ml-library` — Main container.
- `.ml-grid` — Image grid.
- `.ml-tile` — Individual image tile in the grid.
- `.ml-pagination` — Pagination navigation.
- `.ml-modal` — The modal container (in Turbo Frame).

## JavaScript Requirements

The picker uses **dependency-free vanilla JavaScript** (no jQuery, no Stimulus required). It needs:

- ES6 support (const, arrow functions, template literals) — works in all modern browsers (Chrome, Firefox, Safari, Edge).
- `fetch` API for uploading files and fetching paginated images.

If you must support IE11, you'll need polyfills. No Turbo Drive requirement, but Turbo Frames are optional for better UX.

## How It Works

### The Picker Flow

1. **User clicks "Choose from library"** — Opens a modal via a Turbo Frame (`GET /venus_media_library/picker?target=<input_id>`).
2. **Modal loads the image grid** — The frame fetches the index view, listing images newest-first with pagination.
3. **User uploads or selects** —
   - **Select:** Click an image tile; JavaScript writes the blob's `signed_id` and URL into the form inputs and closes the modal.
   - **Upload:** Click the upload button; JavaScript posts the file to `POST /venus_media_library/images`, attaches the new blob to the same inputs, and reloads the grid.
4. **Form submission** — The host app form submits with the image data, storing it as a URL column or Active Storage attachment.

### URL Signing & Storage Agnosticism

All image URLs are built via Active Storage helpers (`rails_blob_url` or `rails_storage_proxy_url`), which handle signed URLs and expiration. The engine never directly accesses the storage backend; it trusts Active Storage to route the request appropriately.

Upload destinations are determined by `config.storage_service` — if `nil`, the host app's default service is used, allowing per-environment configuration (Disk locally, S3 in production).

## Testing

The engine ships with RSpec request, model, and helper specs under `spec/`. To run them:

```bash
cd spec/dummy && bundle exec rspec ../
```

Or use the included Rakefile:

```bash
bundle exec rake app:spec
```

When testing a host app that uses Media Library, you can:

1. **Mock the picker** — Test your form without hitting the engine:
   ```ruby
   it "saves og_image from the picker" do
     visit new_post_path
     fill_in "og_image", with: "https://cdn.example.com/og.jpg"
     click_button "Create"
     expect(post.og_image).to eq("https://cdn.example.com/og.jpg")
   end
   ```

2. **Test the engine in isolation** — Use the dummy app to verify the picker opens, uploads work, and pagination handles large image sets.

## Troubleshooting

### Ownership and community sharing

Each upload is owned by the user returned by `config.current_user` and starts private. A member can browse and download their own uploads; checking **Share with community** during upload makes that item visible to other signed-in members. Admins, as determined by `config.admin`, can browse and download every engine-managed upload.

The engine sends originals and thumbnails through its own authorization-aware routes. Do not use an Active Storage blob URL as a substitute for an engine media URL, because it bypasses the ownership check.

Blobs that existed before the engine was installed have no owner and are intentionally invisible to normal members. Admins can use **Import unowned legacy uploads** from the library to claim an image into their private library, then use the normal community-sharing control if appropriate. Do not expose legacy blobs by direct Active Storage URLs.

### Thumbnails aren't generating

**Symptom:** Gray placeholder squares instead of previews in the grid.

**Solution:** Ensure `libvips` or ImageMagick is installed, and Active Storage is configured. Run:
```bash
rails active_storage:install && rails db:migrate
```

### Private S3 bucket — og:image not visible to crawlers

**Symptom:** Social media preview cards show no image for posts with private S3 URLs.

**Solution:** Set `config.url_type = :proxy` so Rails proxies image bytes through a public endpoint. This requires Rails to stream the file, so monitor for performance impact with large images.

### Upload endpoint is open to the public

**Symptom:** Anyone can upload images to your media library.

**Solution:** Set `config.authenticate_with` in the initializer to gate access. Example:
```ruby
config.authenticate_with = lambda do
  head :forbidden unless current_user&.admin?
end
```

### Form helper `media_picker_field` is undefined

**Symptom:** `undefined method 'media_picker_field'` when rendering a form.

**Solution:** Ensure you've mounted the engine in `config/routes.rb` and the JavaScript is included in your layout with `javascript_include_tag`.

### Picker modal doesn't open or closes immediately

**Symptom:** Button click does nothing or modal opens then closes.

**Solution:** Check browser console for errors. Verify:
1. JavaScript is loaded: `<%= javascript_include_tag "venus_media_library/venus_media_library", defer: true %>`
2. The engine is mounted and accessible at your chosen path (recommended: `/venus_media_library`).
3. No JavaScript errors in other assets are breaking the page.

## Development

The engine ships with a dummy app under `spec/dummy` (Active Storage configured with the Disk service, engine mounted at `/venus_media_library`).

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
