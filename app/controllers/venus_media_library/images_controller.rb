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
      @page     = [ params.fetch(:page, 1).to_i, 1 ].max
      @per_page = per_page
      offset    = (@page - 1) * @per_page

      scope        = image_blobs
      @total_count = scope.count
      @blobs       = scope.order(created_at: :desc).offset(offset).limit(@per_page).to_a
      @has_more    = offset + @blobs.size < @total_count
      @images      = @blobs.map { |blob| ml_image_payload(blob) }

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

      unless allowed_content_type?(uploaded.content_type)
        return respond_error("Content type #{uploaded.content_type} is not allowed.", :unprocessable_entity)
      end

      blob = ActiveStorage::Blob.create_and_upload!(
        io:           uploaded.tempfile,
        filename:     uploaded.original_filename,
        content_type: uploaded.content_type,
        service_name: VenusMediaLibrary.configuration.storage_service
      )

      respond_to do |format|
        format.json { render json: ml_image_payload(blob), status: :created }
        format.html { redirect_to images_path }
      end
    end

    private

    def image_blobs
      ActiveStorage::Blob.where("content_type LIKE ?", "image/%")
    end

    def per_page
      requested = params[:per_page].presence&.to_i
      value = requested&.positive? ? requested : VenusMediaLibrary.configuration.per_page.to_i

      value.clamp(1, MAX_PER_PAGE)
    end

    def allowed_content_type?(content_type)
      return false if content_type.blank?

      Array(VenusMediaLibrary.configuration.allowed_content_types).include?(content_type)
    end

    def respond_error(message, status)
      respond_to do |format|
        format.json { render json: { error: message }, status: status }
        format.html { redirect_to images_path, alert: message }
      end
    end
  end
end
