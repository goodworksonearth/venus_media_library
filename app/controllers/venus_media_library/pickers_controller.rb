module VenusMediaLibrary
  # Renders the picker modal body as a Turbo Frame. `target` is the DOM id of the
  # host input that a chosen image URL / signed_id should be written into.
  class PickersController < ApplicationController
    include VenusMediaLibrary::ImagesHelper

    def show
      @target = params[:target].to_s
      @page   = [ params.fetch(:page, 1).to_i, 1 ].max
      per     = [ VenusMediaLibrary.configuration.per_page.to_i, 1 ].max.clamp(1, ImagesController::MAX_PER_PAGE)
      offset  = (@page - 1) * per

      scope     = visible_media_assets
      @has_more = offset + per < scope.count
      @images   = scope.order(created_at: :desc).offset(offset).limit(per).map { |asset| ml_image_payload(asset) }

      render partial: "venus_media_library/pickers/picker",
             locals: { target: @target, images: @images, page: @page, has_more: @has_more },
             layout: false
    end
  end
end
