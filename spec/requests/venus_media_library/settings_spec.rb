require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "Media Library Settings", type: :request do
    let!(:admin) { Widget.create!(name: "admin") }
    let!(:member) { Widget.create!(name: "member") }

    around do |example|
      configuration = VenusMediaLibrary.configuration
      original_allowed_content_types = configuration.allowed_content_types
      original_max_file_size = configuration.max_file_size
      original_storage_service = configuration.storage_service
      original_static_assets = configuration.static_assets
      original_cloud_assets = configuration.cloud_assets
      example.run
    ensure
      configuration.allowed_content_types = original_allowed_content_types
      configuration.max_file_size = original_max_file_size
      configuration.storage_service = original_storage_service
      configuration.static_assets = original_static_assets
      configuration.cloud_assets = original_cloud_assets
    end

    def create_asset(owner:, community_shared: false)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "photo.png", content_type: "image/png"
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: owner, community_shared: community_shared)
    end

    it "forbids non-admin users from reading configuration" do
      get "/venus_media_library/settings", headers: venus_media_headers(member)

      expect(response).to have_http_status(:forbidden)
    end

    it "shows an admin a read-only configuration and per-view counts" do
      create_asset(owner: admin)
      create_asset(owner: member, community_shared: true)
      configuration = VenusMediaLibrary.configuration
      configuration.allowed_content_types = %w[image/png application/pdf]
      configuration.max_file_size = 2 * 1024 * 1024
      configuration.storage_service = :private_uploads
      configuration.static_assets = -> { [ { filename: "brand.svg", url: "/assets/brand.svg" } ] }
      configuration.cloud_assets = -> { [ { filename: "cdn.png", url: "https://cdn.example.test/cdn.png" } ] }

      get "/venus_media_library/settings.json", headers: venus_media_headers(admin, admin: true)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        "tab_counts" => { "library" => 2, "community" => 1, "static" => 1, "cloud" => 1 },
        "allowed_content_types" => %w[image/png application/pdf],
        "max_file_size" => 2 * 1024 * 1024,
        "storage_service" => "private_uploads"
      )
    end

    it "renders the Settings tab only for administrators" do
      get "/venus_media_library", headers: venus_media_headers(member)
      expect(response.body).not_to include(">Settings<")

      get "/venus_media_library", headers: venus_media_headers(admin, admin: true)
      expect(response.body).to include("/venus_media_library/settings", ">Settings<")
    end
  end
end
