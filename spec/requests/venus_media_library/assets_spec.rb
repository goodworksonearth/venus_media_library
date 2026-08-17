require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "protected asset delivery", type: :request do
    let!(:owner) { Widget.create!(name: "owner") }
    let!(:member) { Widget.create!(name: "member") }

    around do |example|
      configuration = VenusMediaLibrary.configuration
      original_asset_scope = configuration.asset_scope
      original_legacy_blob_scope = configuration.legacy_blob_scope
      example.run
    ensure
      configuration.asset_scope = original_asset_scope
      configuration.legacy_blob_scope = original_legacy_blob_scope
    end

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

      VenusMediaLibrary.configuration.legacy_blob_scope = ->(scope) { scope }

      get "/venus_media_library/legacy_assets.json", headers: venus_media_headers(member, admin: true)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["images"].map { |image| image["id"] }).to include(blob.id)

      post "/venus_media_library/legacy_assets/#{blob.id}/import.json", headers: venus_media_headers(member, admin: true)
      expect(response).to have_http_status(:created)
      expect(VenusMediaLibrary::Asset.find_by(blob: blob)&.owner).to eq(member)
    end

    it "does not expose unowned legacy blobs until the host explicitly scopes them in" do
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "legacy.png", content_type: "image/png"
      )

      get "/venus_media_library/legacy_assets.json", headers: venus_media_headers(member, admin: true)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["images"]).to be_empty
    end

    it "applies the host asset scope before a member sees shared assets" do
      permitted = create_asset(owner: owner, community_shared: true)
      hidden = create_asset(owner: Widget.create!(name: "other"), community_shared: true)
      permitted_owner = owner
      VenusMediaLibrary.configuration.asset_scope = ->(scope) { scope.where(owner: permitted_owner) }

      get "/venus_media_library/images.json", headers: venus_media_headers(member)

      ids = JSON.parse(response.body)["images"].map { |image| image["id"] }
      expect(ids).to include(permitted.id)
      expect(ids).not_to include(hidden.id)
    end

    it "delivers SVG originals as attachments rather than inline documents" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.svg")),
        filename: "logo.svg", content_type: "image/svg+xml"
      )
      asset = VenusMediaLibrary::Asset.create!(blob: blob, owner: owner)

      get "/venus_media_library/assets/#{asset.id}", headers: venus_media_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to start_with("attachment")
    end

    it "delivers enabled PDFs as protected attachments rather than inline documents" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.pdf")),
        filename: "guide.pdf", content_type: "application/pdf"
      )
      asset = VenusMediaLibrary::Asset.create!(blob: blob, owner: owner)

      get "/venus_media_library/assets/#{asset.id}", headers: venus_media_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to start_with("attachment")
    end
  end
end
