require_relative "lib/media_library/version"

Gem::Specification.new do |spec|
  spec.name        = "media_library"
  spec.version     = MediaLibrary::VERSION
  spec.authors     = [ "Good Works On Earth" ]
  spec.email       = [ "hello@goodworksonearth.org" ]
  spec.homepage    = "https://github.com/goodworksonearth/media_library"
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

  spec.metadata["source_code_uri"]   = "https://github.com/goodworksonearth/media_library"
  spec.metadata["changelog_uri"]     = "https://github.com/goodworksonearth/media_library/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "image_processing", "~> 1.12"
end
