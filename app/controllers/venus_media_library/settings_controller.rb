module VenusMediaLibrary
  # Read-only administrator overview. Configuration remains in the host
  # application initializer; this endpoint intentionally never persists
  # credentials, storage settings, or access policy at runtime.
  class SettingsController < ApplicationController
    before_action :require_venus_media_library_admin!

    def show
      configuration = VenusMediaLibrary.configuration
      library_scope = scoped_media_assets
      static_assets = host_assets(configuration.static_assets)
      cloud_assets = host_assets(configuration.cloud_assets)

      @tab_counts = {
        library: library_scope.count,
        community: library_scope.where(community_shared: true).count,
        static: static_assets.size,
        cloud: cloud_assets.size
      }
      @allowed_content_types = Array(configuration.allowed_content_types)
      @max_file_size = configuration.max_file_size.to_i
      @storage_service = configuration.storage_service.presence || "Host application's default Active Storage service"

      respond_to do |format|
        format.html
        format.json do
          render json: {
            tab_counts: @tab_counts,
            allowed_content_types: @allowed_content_types,
            max_file_size: @max_file_size,
            storage_service: @storage_service
          }
        end
      end
    end

    private

    def host_assets(callback)
      Array(instance_exec(&callback)).map { |asset| asset.to_h.symbolize_keys }
    end
  end
end
