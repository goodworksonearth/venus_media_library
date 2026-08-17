module VenusMediaLibrary
  # Shared image URL/payload logic. Included in the views (automatically) and in
  # ImagesController so the HTML grid and the JSON response stay in sync.
  module ImagesHelper
    # A serializable description of a blob used by the JSON API and the tiles.
    def ml_image_payload(asset)
      blob = asset.blob
      {
        id:           asset.id,
        signed_id:    blob.signed_id,
        filename:     blob.filename.to_s,
        content_type: blob.content_type,
        byte_size:    blob.byte_size,
        created_at:   blob.created_at,
        community_shared: asset.community_shared,
        url:          ml_blob_url(asset),
        thumb_url:    ml_thumb_url(asset)
      }
    end

    # Permanent URL to the original file. Active Storage route helpers live on the
    # host app, so they are reached through the `main_app` proxy. With
    # url_type = :proxy the URL streams through Rails (works for private buckets
    # and external crawlers); the default :redirect 302s to the storage URL.
    def ml_blob_url(asset)
      venus_media_library.asset_path(asset)
    end

    # Small variant used for the grid thumbnail. Falls back to the original URL
    # when the blob can't be variated (e.g. SVG).
    def ml_thumb_url(asset)
      venus_media_library.thumbnail_asset_path(asset)
    end
  end
end
