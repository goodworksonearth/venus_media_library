module VenusMediaLibrary
  class AssetsController < ApplicationController
    def show
      asset = visible_media_assets.find(params[:id])
      send_data asset.blob.download, filename: asset.blob.filename.to_s,
        type: asset.blob.content_type, disposition: delivery_disposition(asset.blob)
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

    private

    # SVG is accepted for editorial use but is delivered as a download. Inline
    # SVG may execute active content in a host application's origin. PDFs are
    # also attachments: they remain selectable media but are not embedded in
    # the host application's origin.
    def delivery_disposition(blob)
      [ "image/svg+xml", "application/pdf" ].include?(blob.content_type) ? "attachment" : "inline"
    end
  end
end
