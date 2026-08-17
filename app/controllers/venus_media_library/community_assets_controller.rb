module VenusMediaLibrary
  class CommunityAssetsController < ApplicationController
    include VenusMediaLibrary::ImagesHelper

    def index
      load_media_assets(scoped_media_assets.where(community_shared: true))

      respond_to do |format|
        format.html
        format.json do
          render json: { images: @images, page: @page, has_more: @has_more, total: @total_count }
        end
      end
    end
  end
end
