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
        previewable:  ml_previewable?(blob),
        thumb_url:    ml_previewable?(blob) ? ml_thumb_url(asset) : nil
      }
    end

    # Permanent, PUBLIC URL to the original file — this is the value the picker
    # writes into a host URL field (e.g. a page's og:image), so it must be
    # absolute and fetchable by external crawlers (Facebook/Google/Twitter) with
    # no session. It therefore uses Rails' public Active Storage routes, NOT the
    # engine's owner-gated `asset_path` (an anonymous crawler hitting that route
    # is bounced by the host's `authenticate_with` gate, silently breaking
    # og:image / social cards). Owner-scoping still governs WHICH assets a member
    # can SEE in the library (see visible_media_assets); it is orthogonal to the
    # public URL a picked asset resolves to. Active Storage route helpers live on
    # the host app, so they are reached through the `main_app` proxy. With
    # url_type = :proxy the URL streams through Rails (works for private buckets);
    # the default :redirect 302s to the storage URL. Mirrors PickerHelper's
    # attach-mode preview so URL fields and attachment fields agree.
    def ml_blob_url(asset)
      if VenusMediaLibrary.configuration.url_type == :proxy
        main_app.rails_storage_proxy_url(asset.blob)
      else
        main_app.rails_blob_url(asset.blob)
      end
    rescue StandardError
      # Last resort only: a relative path keeps the admin grid rendering when a
      # URL host is unavailable. Absolute public URLs above are what host URL
      # fields need; this fallback should not be the stored og:image value.
      main_app.rails_blob_path(asset.blob)
    end

    # Small variant used for the in-admin grid thumbnail. This runs behind the
    # engine's auth in the admin library UI, so the owner-scoped engine route is
    # correct here (it also honors the per-tenant visibility rules). Only the
    # picked `url` above needs to be public.
    def ml_thumb_url(asset)
      venus_media_library.thumbnail_asset_path(asset)
    end

    # A PDF is a selectable media asset, but it must never be embedded in the
    # picker or the library grid. The protected original route sends it as an
    # attachment, and the UI renders a descriptive document tile instead.
    def ml_previewable?(blob)
      blob.content_type.to_s.start_with?("image/") && blob.content_type != "image/svg+xml"
    end
  end
end
