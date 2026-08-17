module VenusMediaLibrary
  class LegacyAssetsController < ApplicationController
    include VenusMediaLibrary::ImagesHelper
    before_action :require_venus_media_library_admin!

    def index
      @legacy_blobs = unowned_legacy_image_blobs.order(created_at: :desc)

      respond_to do |format|
        format.html
        format.json { render json: { images: @legacy_blobs.map { |blob| legacy_image_payload(blob) } } }
      end
    end

    def show
      blob = unowned_legacy_image_blobs.find(params[:id])
      send_data blob.download, filename: blob.filename.to_s, type: blob.content_type, disposition: "inline"
    end

    def thumbnail
      blob = unowned_legacy_image_blobs.find(params[:id])
      return redirect_to legacy_asset_path(blob) unless blob.variable?

      width, height = VenusMediaLibrary.configuration.thumbnail_size
      representation = blob.variant(resize_to_limit: [ width, height ]).processed
      send_data representation.download, filename: blob.filename.to_s,
        type: representation.image.content_type, disposition: "inline"
    end

    def import
      blob = unowned_legacy_image_blobs.find(params[:id])
      asset = VenusMediaLibrary::Asset.create!(blob: blob, owner: venus_media_library_user)

      respond_to do |format|
        format.html { redirect_to images_path, notice: "Legacy upload imported into your private library." }
        format.json { render json: ml_image_payload(asset), status: :created }
      end
    end

    private

    def legacy_image_payload(blob)
      {
        id: blob.id,
        filename: blob.filename.to_s,
        content_type: blob.content_type,
        byte_size: blob.byte_size,
        created_at: blob.created_at,
        url: legacy_asset_path(blob),
        thumb_url: thumbnail_legacy_asset_path(blob)
      }
    end
  end
end
