require "media_library/version"
require "media_library/engine"

module MediaLibrary
  # Host apps configure the engine through `MediaLibrary.configure`:
  #
  #   MediaLibrary.configure do |config|
  #     config.allowed_content_types = %w[image/png image/jpeg image/webp]
  #     config.thumbnail_size        = [ 300, 300 ]
  #     config.per_page              = 40
  #     config.storage_service       = :amazon
  #   end
  class Configuration
    # Content types accepted by the uploader and shown in the library grid.
    # Every entry is matched literally; the index additionally shows any blob
    # whose content_type starts with "image/".
    attr_accessor :allowed_content_types

    # [width, height] used for the grid thumbnail variant.
    attr_accessor :thumbnail_size

    # Number of images per page in the index.
    attr_accessor :per_page

    # Optional Active Storage service name to attach uploads to. When nil the
    # host app's default service (`config.active_storage.service`) is used, so
    # the engine stays storage-agnostic (Disk in dev, S3 in prod, etc.).
    attr_accessor :storage_service

    def initialize
      @allowed_content_types = %w[image/png image/jpeg image/jpg image/gif image/webp image/svg+xml]
      @thumbnail_size        = [ 300, 300 ]
      @per_page              = 40
      @storage_service       = nil
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
