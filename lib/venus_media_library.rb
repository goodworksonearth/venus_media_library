require "venus_media_library/version"
require "venus_media_library/engine"

module VenusMediaLibrary
  # Host apps configure the engine through `VenusMediaLibrary.configure`:
  #
  #   VenusMediaLibrary.configure do |config|
  #     config.allowed_content_types = %w[image/png image/jpeg image/webp]
  #     config.thumbnail_size        = [ 300, 300 ]
  #     config.per_page              = 40
  #     config.storage_service       = :amazon
  #   end
  class Configuration
    # Content types accepted by the uploader. Every entry is matched literally.
    attr_accessor :allowed_content_types

    # [width, height] used for the grid thumbnail variant.
    attr_accessor :thumbnail_size

    # Number of media assets per page in the index.
    attr_accessor :per_page

    # Maximum accepted upload size in bytes.
    attr_accessor :max_file_size

    # Optional Active Storage service name to attach uploads to. When nil the
    # host app's default service (`config.active_storage.service`) is used, so
    # the engine stays storage-agnostic (Disk in dev, S3 in prod, etc.).
    attr_accessor :storage_service

    # Retained for compatibility with older host configuration. Library URLs are
    # always served through authorization-aware engine routes.
    attr_accessor :url_type

    # Optional access gate. A proc run in the engine controller's context before
    # every action (via instance_exec), so it can call host helpers like
    # `current_user`, `redirect_to`, or `head`. Left nil the engine is open; the
    # host sets this to restrict the picker/upload endpoints to admins.
    #
    #   VenusMediaLibrary.configure do |c|
    #     c.authenticate_with = -> { redirect_to main_app.root_path unless current_user&.admin? }
    #   end
    attr_accessor :authenticate_with
    # The current signed-in host user and the role predicate. Both callbacks run
    # in the engine controller context. By default this uses the host's
    # `current_user` and `current_user.admin?` convention.
    attr_accessor :current_user, :admin

    # Controller-context callbacks that narrow the engine's records for a host
    # tenant. Each receives an Active Record relation and must return a relation.
    # Legacy blobs default to none because they have no owner and may belong to
    # another tenant.
    attr_accessor :asset_scope, :legacy_blob_scope

    # Controller-context callback returning static asset hashes supplied by the
    # host. Each hash should include :filename and :url, with optional
    # :content_type and :byte_size. The engine never scans host directories.
    attr_accessor :static_assets

    # Controller-context callback returning approved cloud asset hashes supplied
    # by the host. This has the same shape as `static_assets` and intentionally
    # does not enumerate a cloud bucket or expose storage-provider credentials.
    attr_accessor :cloud_assets

    # Default admin predicate. A gem shouldn't break just because a host app names
    # its flag differently, so try the two common conventions — `admin?` then
    # `is_admin?` — and fall back to non-admin. Hosts with any other scheme set
    # their own `config.admin = ->(user) { ... }`.
    DEFAULT_ADMIN = lambda do |user|
      return false if user.nil?
      return !!user.admin? if user.respond_to?(:admin?)
      return !!user.is_admin? if user.respond_to?(:is_admin?)

      false
    end

    def initialize
      @allowed_content_types = %w[image/png image/jpeg image/jpg image/gif image/webp image/svg+xml]
      @thumbnail_size        = [ 300, 300 ]
      @per_page              = 40
      @max_file_size         = 10 * 1024 * 1024
      @storage_service       = nil
      @url_type              = :redirect
      @authenticate_with     = nil
      @current_user          = -> { current_user }
      @admin                 = DEFAULT_ADMIN
      @asset_scope           = ->(scope) { scope }
      @legacy_blob_scope     = ->(scope) { scope.none }
      @static_assets         = -> { [] }
      @cloud_assets          = -> { [] }
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    # Test/host reset hook.
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
