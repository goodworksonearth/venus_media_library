module MediaLibrary
  # Renders the picker modal body as a Turbo Frame. `target` is the DOM id of the
  # host input that a chosen image URL / signed_id should be written into.
  class PickersController < ApplicationController
    include MediaLibrary::ImagesHelper

    def show
      @target = params[:target].to_s
      @page   = [ params.fetch(:page, 1).to_i, 1 ].max
      per     = MediaLibrary.configuration.per_page
      offset  = (@page - 1) * per

      scope     = ActiveStorage::Blob.where("content_type LIKE ?", "image/%")
      @has_more = offset + per < scope.count
      @images   = scope.order(created_at: :desc).offset(offset).limit(per).map { |blob| ml_image_payload(blob) }

      render partial: "media_library/pickers/picker",
             locals: { target: @target, images: @images, page: @page, has_more: @has_more },
             layout: false
    end
  end
end
