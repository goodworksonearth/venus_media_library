module VenusMediaLibrary
  class AssetsController < ApplicationController
    def show
      asset = visible_media_assets.find(params[:id])
      send_data asset.blob.download, filename: asset.blob.filename.to_s,
        type: asset.blob.content_type, disposition: "inline"
    end

    def thumbnail
      asset = visible_media_assets.find(params[:id])
      blob = asset.blob
      return redirect_to asset_path(asset) unless blob.variable?

      width, height = VenusMediaLibrary.configuration.thumbnail_size
      representation = blob.variant(resize_to_limit: [ width, height ]).processed
      send_data representation.download, filename: blob.filename.to_s,
        type: representation.image.content_type, disposition: "inline"
    end
  end
end
