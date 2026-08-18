require_relative "lib/venus_media_library/version"

Gem::Specification.new do |spec|
  spec.name        = "venus_media_library"
  spec.version     = VenusMediaLibrary::VERSION
  spec.authors     = [ "Good Works On Earth" ]
  spec.email       = [ "hello@goodworksonearth.org" ]
  spec.homepage    = "https://github.com/goodworksonearth/venus_media_library"
  spec.summary     = "A mountable Rails engine that turns Active Storage into a browsable media library with an image picker."
  spec.description = <<~DESC.strip
    Media Library is a mountable Rails engine that lists images stored in Active Storage
    (S3, Google Cloud Storage, Disk — whatever the host app configures) and gives content
    editors a modal image picker. Drop `media_picker_field` next to any URL field (such as
    an og:image field) so editors can select an existing image or upload a new one instead
    of typing a path. Storage-agnostic, namespaced, and publishable.
  DESC
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"]   = "https://github.com/goodworksonearth/venus_media_library"
  spec.metadata["changelog_uri"]     = "https://github.com/goodworksonearth/venus_media_library/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/goodworksonearth/venus_media_library/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Ship only the runtime engine (no specs/dummy app) in the published gem.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end
  spec.require_paths = [ "lib" ]

  spec.add_dependency "rails", ">= 7.1", "< 9.0"
  spec.add_dependency "image_processing", ">= 1.12", "< 3.0"
  # image_processing >= 2.0 dropped the MiniMagick backend and is libvips-only, so
  # the vips Ruby binding must be present for ActiveStorage variant processing to
  # boot. Declaring it here means host apps get a working image pipeline out of the
  # box (the OS-level libvips is still required — see docs/RELEASING.md / CI).
  spec.add_dependency "ruby-vips", ">= 2.1"
end
