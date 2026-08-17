module VenusMediaLibrary
  # Shared image URL/payload logic. Included in the views (automatically) and in
  # ImagesController so the HTML grid and the JSON response stay in sync.
  module ImagesHelper
    # A serializable description of a blob used by the JSON API and the tiles.
    def ml_image_payload(blob)
      {
        id:           blob.id,
        signed_id:    blob.signed_id,
        filename:     blob.filename.to_s,
        content_type: blob.content_type,
        byte_size:    blob.byte_size,
        created_at:   blob.created_at,
        url:          ml_blob_url(blob),
        thumb_url:    ml_thumb_url(blob)
      }
    end

    # Permanent URL to the original file. Active Storage route helpers live on the
    # host app, so they are reached through the `main_app` proxy. With
    # url_type = :proxy the URL streams through Rails (works for private buckets
    # and external crawlers); the default :redirect 302s to the storage URL.
    def ml_blob_url(blob)
      if VenusMediaLibrary.configuration.url_type == :proxy
        main_app.rails_storage_proxy_url(blob)
      else
        main_app.rails_blob_url(blob)
      end
    rescue StandardError
      main_app.rails_blob_path(blob)
    end

    # Small variant used for the grid thumbnail. Falls back to the original URL
    # when the blob can't be variated (e.g. SVG).
    def ml_thumb_url(blob)
      if blob.variable?
        w, h = VenusMediaLibrary.configuration.thumbnail_size
        main_app.rails_representation_url(blob.variant(resize_to_limit: [ w, h ]))
      else
        ml_blob_url(blob)
      end
    rescue StandardError
      ml_blob_url(blob)
    end
  end
end
