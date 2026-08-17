require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "protected asset delivery", type: :request do
    let!(:owner) { Widget.create!(name: "owner") }
    let!(:member) { Widget.create!(name: "member") }

    def create_asset(owner: self.owner, community_shared: false)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "private.png", content_type: "image/png"
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: owner, community_shared: community_shared)
    end

    it "serves a private original only to its owner or an admin" do
      asset = create_asset

      get "/venus_media_library/assets/#{asset.id}", headers: venus_media_headers(member)
      expect(response).to have_http_status(:not_found)

      get "/venus_media_library/assets/#{asset.id}", headers: venus_media_headers(owner)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")

      get "/venus_media_library/assets/#{asset.id}", headers: venus_media_headers(member, admin: true)
      expect(response).to have_http_status(:ok)
    end

    it "lets community members retrieve explicitly shared assets" do
      asset = create_asset(community_shared: true)

      get "/venus_media_library/assets/#{asset.id}/thumbnail", headers: venus_media_headers(member)

      expect(response).to have_http_status(:ok)
    end

    it "keeps unowned legacy blobs invisible to members and lets an admin import one" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "legacy.png", content_type: "image/png"
      )

      get "/venus_media_library/legacy_assets.json", headers: venus_media_headers(member)
      expect(response).to have_http_status(:forbidden)

      get "/venus_media_library/legacy_assets.json", headers: venus_media_headers(member, admin: true)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["images"].map { |image| image["id"] }).to include(blob.id)

      post "/venus_media_library/legacy_assets/#{blob.id}/import.json", headers: venus_media_headers(member, admin: true)
      expect(response).to have_http_status(:created)
      expect(VenusMediaLibrary::Asset.find_by(blob: blob)&.owner).to eq(member)
    end
  end
end
