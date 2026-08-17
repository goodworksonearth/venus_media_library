module VenusMediaLibrary
  class ApplicationController < ActionController::Base
    helper_method :venus_media_library_admin?
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

    def visible_media_assets
      scope = VenusMediaLibrary::Asset.includes(:blob)
      return scope if venus_media_library_admin?

      scope.where(community_shared: true).or(scope.where(owner: venus_media_library_user))
    end

    def unowned_legacy_image_blobs
      ActiveStorage::Blob.where("content_type LIKE ?", "image/%")
                         .where.not(id: VenusMediaLibrary::Asset.select(:blob_id))
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
