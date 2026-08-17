module VenusMediaLibrary
  class CloudAssetsController < ApplicationController
    def index
      load_host_assets(VenusMediaLibrary.configuration.cloud_assets)

      respond_to do |format|
        format.html
        format.json { render json: { assets: @assets } }
      end
    end
  end
end
