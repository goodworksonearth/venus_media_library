module VenusMediaLibrary
  # Lists and uploads images backed by Active Storage. Storage-agnostic: it uses
  # whatever service the host app configures (Disk in dev, S3 in prod, ...).
  class ImagesController < ApplicationController
    include VenusMediaLibrary::ImagesHelper

    MAX_PER_PAGE = 100

    # GET /images
    # Lists image blobs, newest first, with simple offset pagination.
    # Responds with an HTML grid or a JSON payload for the picker.
    def index
      load_media_assets(visible_media_assets)

      respond_to do |format|
        format.html # index.html.erb
        format.json do
          render json: { images: @images, page: @page, has_more: @has_more, total: @total_count }
        end
      end
    end

    # POST /images
    # Accepts an uploaded file and stores it via Active Storage.
    def create
      uploaded = params[:file] || params.dig(:image, :file)

      if uploaded.blank?
        return respond_error("No file was uploaded.", :unprocessable_entity)
      end

      detected_content_type = validated_content_type(uploaded)
      return unless detected_content_type
      return unless field_accepts?(detected_content_type)

      blob = ActiveStorage::Blob.create_and_upload!(
        io:           uploaded.tempfile,
        filename:     uploaded.original_filename,
        content_type: detected_content_type,
        service_name: VenusMediaLibrary.configuration.storage_service
      )
      asset = VenusMediaLibrary::Asset.create!(
        blob: blob, owner: venus_media_library_user,
        community_shared: ActiveModel::Type::Boolean.new.cast(params[:community_shared]) || false
      )

      respond_to do |format|
        format.json { render json: ml_image_payload(asset), status: :created }
        format.html { redirect_to images_path }
      end
    rescue ActiveRecord::RecordInvalid
      blob&.purge
      raise
    end

    private

    def allowed_content_type?(content_type)
      return false if content_type.blank?

      Array(VenusMediaLibrary.configuration.allowed_content_types).include?(content_type)
    end

    # When the picker was opened for a field that declares accepted types, the
    # upload must satisfy them too (not just the global allowlist). The `accept`
    # param travels from the field through the picker frame to this upload.
    def field_accepts?(content_type)
      field_types = AcceptedTypes.parse(params[:accept])
      return true unless field_types.any?
      return true if field_types.matches?(content_type)

      respond_error("Content type #{content_type} is not accepted by this field.", :unprocessable_entity)
      false
    end

    def validated_content_type(uploaded)
      if uploaded.size.to_i > VenusMediaLibrary.configuration.max_file_size.to_i
        respond_error("File is larger than the #{VenusMediaLibrary.configuration.max_file_size} byte upload limit.", :unprocessable_entity)
        return
      end

      detected = Marcel::MimeType.for(uploaded.tempfile, name: uploaded.original_filename)
      unless allowed_content_type?(detected)
        respond_error("Detected content type #{detected} is not allowed.", :unprocessable_entity)
        return
      end

      if uploaded.content_type != detected
        respond_error("Declared content type does not match the uploaded file.", :unprocessable_entity)
        return
      end

      detected
    ensure
      uploaded.tempfile.rewind if uploaded&.tempfile&.respond_to?(:rewind)
    end

    def respond_error(message, status)
      respond_to do |format|
        format.json { render json: { error: message }, status: status }
        format.html { redirect_to images_path, alert: message }
      end
    end
  end
end
