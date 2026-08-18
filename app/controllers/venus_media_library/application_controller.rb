module VenusMediaLibrary
  class ApplicationController < ActionController::Base
    helper_method :venus_media_library_admin?,
                  :venus_media_library_nav_items,
                  :venus_media_library_active_nav
    # Run the host-configured access gate (if any) before every engine action.
    # The engine ships open; the host restricts the picker/upload endpoints by
    # setting VenusMediaLibrary.configuration.authenticate_with to a proc.
    before_action :authenticate_venus_media_library_access!
    before_action :require_venus_media_library_user!

    private

    def authenticate_venus_media_library_access!
      gate = VenusMediaLibrary.configuration.authenticate_with
      return unless gate.respond_to?(:call)

      # instance_exec so the proc runs in this controller's context and can use
      # host helpers (current_user, redirect_to, head, main_app, ...).
      instance_exec(&gate)
    end

    def venus_media_library_user
      return @venus_media_library_user if defined?(@venus_media_library_user)

      @venus_media_library_user = instance_exec(&VenusMediaLibrary.configuration.current_user)
    end

    def venus_media_library_admin?
      instance_exec(venus_media_library_user, &VenusMediaLibrary.configuration.admin)
    end

    # Destinations for the full-page management workspace's left navigation.
    # Role-gated: legacy imports and the settings overview are admin-only,
    # mirroring the `require_venus_media_library_admin!` gate those controllers
    # already enforce, so the sidebar never advertises a forbidden link.
    def venus_media_library_nav_items
      items = [
        { key: :library,   controller: "images",           label: "My Library",    path: images_path },
        { key: :legacy,    controller: "legacy_assets",    label: "Legacy Assets", path: legacy_assets_path, admin: true },
        { key: :static,    controller: "static_assets",    label: "Static Assets", path: static_assets_path },
        { key: :cloud,     controller: "cloud_assets",     label: "Cloud Assets",  path: cloud_assets_path },
        { key: :community, controller: "community_assets", label: "Community",     path: community_assets_path },
        { key: :settings,  controller: "settings",         label: "Settings",      path: settings_path, admin: true }
      ]
      return items if venus_media_library_admin?

      items.reject { |item| item[:admin] }
    end

    # The nav key for the controller handling the current request, used by the
    # sidebar to highlight the active section without each view passing a local.
    def venus_media_library_active_nav
      venus_media_library_nav_items.find { |item| item[:controller] == controller_name }&.fetch(:key)
    end

    def visible_media_assets
      scope = scoped_media_assets
      return scope if venus_media_library_admin?

      scope.where(community_shared: true).or(scope.where(owner: venus_media_library_user))
    end

    def unowned_legacy_image_blobs
      scope = ActiveStorage::Blob.where("content_type LIKE ?", "image/%")
                                 .where.not(id: VenusMediaLibrary::Asset.select(:blob_id))
      instance_exec(scope, &VenusMediaLibrary.configuration.legacy_blob_scope)
    end

    def scoped_media_assets
      scope = VenusMediaLibrary::Asset.includes(:blob)
      instance_exec(scope, &VenusMediaLibrary.configuration.asset_scope)
    end

    def load_media_assets(scope)
      @page     = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = requested_per_page
      offset    = (@page - 1) * @per_page

      @total_count = scope.count
      @blobs       = scope.order(created_at: :desc).offset(offset).limit(@per_page).to_a
      @has_more    = offset + @blobs.size < @total_count
      @images      = @blobs.map { |asset| ml_image_payload(asset) }
    end

    def load_host_assets(callback)
      @assets = Array(instance_exec(&callback)).map do |asset|
        asset.to_h.symbolize_keys.slice(:filename, :url, :content_type, :byte_size)
      end
    end

    def requested_per_page
      requested = params[:per_page].presence&.to_i
      value = requested&.positive? ? requested : VenusMediaLibrary.configuration.per_page.to_i

      value.clamp(1, ImagesController::MAX_PER_PAGE)
    end

    def require_venus_media_library_admin!
      return if venus_media_library_admin?

      head :forbidden
    end

    def require_venus_media_library_user!
      return if venus_media_library_user

      head :unauthorized
    end
  end
end
