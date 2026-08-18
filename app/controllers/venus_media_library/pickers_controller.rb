module VenusMediaLibrary
  # Renders the picker modal body as a Turbo Frame. `target` is the DOM id of the
  # host input that a chosen asset's URL / signed_id is written into. `accept`
  # carries the opening field's accepted content types so the modal can filter
  # which assets are selectable and constrain uploads. `category` selects which
  # asset collection (images / legacy / static / cloud / community) to show; each
  # category is a tab that reloads this same frame.
  class PickersController < ApplicationController
    include VenusMediaLibrary::ImagesHelper

    # Selectable asset collections, in tab order. Legacy is admin-only, mirroring
    # the LegacyAssetsController gate, so the picker never offers it to members.
    CATEGORIES = [
      { key: "library",   label: "Images" },
      { key: "legacy",    label: "Legacy",    admin: true },
      { key: "static",    label: "Static" },
      { key: "cloud",     label: "Cloud" },
      { key: "community", label: "Community" }
    ].freeze

    def show
      @target   = params[:target].to_s
      @category = requested_category
      @accepted = picker_accepted_types
      @accept_attr = picker_input_accept
      @tabs     = picker_tabs
      @items    = picker_items

      render partial: "venus_media_library/pickers/picker",
             locals: {
               target: @target, category: @category, accept: params[:accept].to_s.presence,
               accept_attr: @accept_attr, tabs: @tabs, items: @items,
               page: @page, has_more: @has_more
             },
             layout: false
    end

    private

    def requested_category
      key = params[:category].to_s.presence || "library"
      CATEGORIES.any? { |category| category[:key] == key } ? key : "library"
    end

    # Tabs the current user may use — admin-only categories are dropped for members.
    def picker_tabs
      CATEGORIES.reject { |category| category[:admin] && !venus_media_library_admin? }
    end

    # The field's accepted types, or the global allowlist when the field declares
    # nothing. Selection matching is driven by this.
    def picker_accepted_types
      field = AcceptedTypes.parse(params[:accept])
      return field if field.any?

      AcceptedTypes.new(Array(VenusMediaLibrary.configuration.allowed_content_types))
    end

    # Value for the upload <input accept>: the field's declared types when given,
    # else the globally allowed types (unchanged from the pre-field behavior).
    def picker_input_accept
      field = AcceptedTypes.parse(params[:accept])
      return field.to_input_accept if field.any?

      Array(VenusMediaLibrary.configuration.allowed_content_types).join(",")
    end

    def picker_items
      case @category
      when "community"
        paginated_asset_items(scoped_media_assets.where(community_shared: true))
      when "legacy"
        legacy_items
      when "static"
        host_asset_items(VenusMediaLibrary.configuration.static_assets)
      when "cloud"
        host_asset_items(VenusMediaLibrary.configuration.cloud_assets)
      else
        paginated_asset_items(visible_media_assets)
      end
    end

    # Owner/community assets paginate like the library index; other categories are
    # small host-supplied lists and render in full.
    def paginated_asset_items(scope)
      @page     = [ params.fetch(:page, 1).to_i, 1 ].max
      per       = [ VenusMediaLibrary.configuration.per_page.to_i, 1 ].max.clamp(1, ImagesController::MAX_PER_PAGE)
      offset    = (@page - 1) * per
      @has_more = offset + per < scope.count

      scope.order(created_at: :desc).offset(offset).limit(per).map { |asset| asset_item(asset) }
    end

    def asset_item(asset)
      selectable_item(ml_image_payload(asset))
    end

    def legacy_items
      @has_more = false
      return [] unless venus_media_library_admin?

      unowned_legacy_image_blobs.order(created_at: :desc).map do |blob|
        selectable_item(
          signed_id:    blob.signed_id,
          filename:     blob.filename.to_s,
          content_type: blob.content_type,
          url:          legacy_asset_path(blob),
          previewable:  ml_previewable?(blob),
          thumb_url:    ml_previewable?(blob) ? thumbnail_legacy_asset_path(blob) : nil
        )
      end
    end

    # Host static/cloud assets are external URLs with no blob, so they carry no
    # signed_id: pickable into a URL field, but not attachable to a
    # has_one_attached. The JS leaves the hidden attach field untouched when the
    # signed_id is blank so choosing one can never detach an existing file.
    def host_asset_items(callback)
      @has_more = false
      Array(instance_exec(&callback)).map do |asset|
        data = asset.to_h.symbolize_keys
        content_type = data[:content_type].to_s
        selectable_item(
          signed_id:    nil,
          filename:     data[:filename],
          content_type: content_type,
          url:          data[:url],
          previewable:  content_type.start_with?("image/") && content_type != "image/svg+xml",
          thumb_url:    content_type.start_with?("image/") ? data[:url] : nil
        )
      end
    end

    # Stamps each tile payload with whether the opening field accepts its type.
    def selectable_item(payload)
      payload.merge(selectable: @accepted.matches?(payload[:content_type]))
    end
  end
end
