require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "access control", type: :request do
    let!(:member) { Widget.create!(name: "member") }

    around do |example|
      original = VenusMediaLibrary.configuration.authenticate_with
      example.run
      VenusMediaLibrary.configuration.authenticate_with = original
    end

    it "requires a current user even when no additional authenticator is configured" do
      VenusMediaLibrary.configuration.authenticate_with = nil

      get "/venus_media_library/images.json"

      expect(response).to have_http_status(:unauthorized)
    end

    it "runs the configured authenticator in controller context and can deny" do
      VenusMediaLibrary.configuration.authenticate_with = -> { head :forbidden }

      get "/venus_media_library/images.json", headers: venus_media_headers(member)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
