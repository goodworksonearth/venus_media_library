require "rails_helper"

module VenusMediaLibrary
  # The engine exposes an upload/list endpoint, so the host must be able to gate
  # it (admins only). config.authenticate_with is a proc run in the controller's
  # context before every action; the host uses it to redirect/deny non-admins.
  RSpec.describe "access control", type: :request do
    around do |example|
      original = VenusMediaLibrary.configuration.authenticate_with
      example.run
      VenusMediaLibrary.configuration.authenticate_with = original
    end

    it "allows access when no authenticator is configured (default)" do
      VenusMediaLibrary.configuration.authenticate_with = nil

      get "/media/images.json"

      expect(response).to have_http_status(:ok)
    end

    it "runs the configured authenticator in controller context and can deny" do
      VenusMediaLibrary.configuration.authenticate_with = lambda do
        head :forbidden
      end

      get "/media/images.json"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
