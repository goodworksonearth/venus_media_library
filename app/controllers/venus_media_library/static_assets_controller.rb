module VenusMediaLibrary
  class StaticAssetsController < ApplicationController
    def index
      @assets = Array(instance_exec(&VenusMediaLibrary.configuration.static_assets)).map do |asset|
        asset.to_h.symbolize_keys.slice(:filename, :url, :content_type, :byte_size)
      end

      respond_to do |format|
        format.html
        format.json { render json: { assets: @assets } }
      end
    end
  end
end
