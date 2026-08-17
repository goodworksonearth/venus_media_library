require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "Images", type: :request do
    let!(:member) { Widget.create!(name: "member") }

    around do |example|
      configuration = VenusMediaLibrary.configuration
      original_content_types = configuration.allowed_content_types
      original_max_file_size = configuration.max_file_size
      original_static_assets = configuration.static_assets
      original_cloud_assets = configuration.cloud_assets
      example.run
      configuration.allowed_content_types = original_content_types
      configuration.max_file_size = original_max_file_size
      configuration.static_assets = original_static_assets
      configuration.cloud_assets = original_cloud_assets
    end

    def create_image_asset(owner: member, filename: "existing.png", content_type: "image/png", community_shared: false)
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: filename,
        content_type: content_type
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: owner, community_shared: community_shared)
    end

    describe "GET /venus_media_library" do
      it "renders the member's browsable library at the mounted root" do
        create_image_asset(filename: "library.png")

        get "/venus_media_library", headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Media Library", "library.png", "My Library", "Community", "Static Assets", "Cloud Assets")
        expect(response.body).to include("venus_media_library/application", "venus_media_library/picker", "venus_media_library/venus_media_library")
      end
    end

    describe "GET /venus_media_library/images" do
      it "returns the member's image assets as JSON, newest first" do
        old = create_image_asset(filename: "old.png")
        new = create_image_asset(filename: "new.png")
        other = create_image_asset(owner: Widget.create!(name: "other"), filename: "private.png")

        get "/venus_media_library/images.json", headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        ids = body["images"].map { |image| image["id"] }

        expect(ids).to include(old.id, new.id)
        expect(ids).not_to include(other.id)
        expect(ids.index(new.id)).to be < ids.index(old.id)
        expect(body["images"].first).to include("signed_id", "url", "thumb_url", "community_shared")
      end

      it "shows shared uploads from other members" do
        shared = create_image_asset(owner: Widget.create!(name: "other"), filename: "shared.png", community_shared: true)

        get "/venus_media_library/images.json", headers: venus_media_headers(member)

        expect(JSON.parse(response.body)["images"].map { |image| image["id"] }).to include(shared.id)
      end

      it "renders an HTML grid" do
        create_image_asset(filename: "grid.png")

        get "/venus_media_library/images", headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ml-grid", "grid.png")
      end

      it "paginates" do
        get "/venus_media_library/images.json", params: { page: 2, per_page: 1 }, headers: venus_media_headers(member)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["page"]).to eq(2)
      end

      it "requires a signed-in user" do
        get "/venus_media_library/images.json"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "GET /venus_media_library/static_assets" do
      it "lists only host-configured static assets" do
        VenusMediaLibrary.configuration.static_assets = lambda do
          [ { filename: "brand.svg", url: "/assets/brand.svg", content_type: "image/svg+xml" } ]
        end

        get "/venus_media_library/static_assets.json", headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["assets"]).to include("filename" => "brand.svg", "url" => "/assets/brand.svg", "content_type" => "image/svg+xml")
      end
    end

    describe "GET /venus_media_library/community_assets" do
      it "lists only tenant-scoped assets explicitly shared with the community" do
        shared = create_image_asset(owner: Widget.create!(name: "other"), filename: "shared.png", community_shared: true)
        private_asset = create_image_asset(owner: Widget.create!(name: "private-owner"), filename: "private.png")

        get "/venus_media_library/community_assets.json", headers: venus_media_headers(member)

        ids = JSON.parse(response.body)["images"].map { |image| image["id"] }
        expect(ids).to include(shared.id)
        expect(ids).not_to include(private_asset.id)
      end
    end

    describe "GET /venus_media_library/cloud_assets" do
      it "lists only host-configured cloud assets" do
        VenusMediaLibrary.configuration.cloud_assets = lambda do
          [ { filename: "remote-logo.svg", url: "https://cdn.example.test/remote-logo.svg", content_type: "image/svg+xml" } ]
        end

        get "/venus_media_library/cloud_assets.json", headers: venus_media_headers(member)

        expect(JSON.parse(response.body)["assets"]).to include(
          "filename" => "remote-logo.svg", "url" => "https://cdn.example.test/remote-logo.svg", "content_type" => "image/svg+xml"
        )
      end
    end

    describe "POST /venus_media_library/images" do
      it "uploads a private asset owned by the current user" do
        file = fixture_file_upload("sample.png", "image/png")

        expect {
          post "/venus_media_library/images.json", params: { file: file }, headers: venus_media_headers(member)
        }.to change(VenusMediaLibrary::Asset, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        asset = VenusMediaLibrary::Asset.find(body["id"])
        expect(asset.owner).to eq(member)
        expect(asset).not_to be_community_shared
        expect(asset.blob.download.bytesize).to eq(File.size(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")))
      end

      it "uploads SVG files by default and shares only when requested" do
        file = fixture_file_upload("sample.svg", "image/svg+xml")

        post "/venus_media_library/images.json", params: { file: file, community_shared: "1" }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body).to include("content_type" => "image/svg+xml", "community_shared" => true)
      end

      it "honors a narrowed configured allowlist" do
        VenusMediaLibrary.configuration.allowed_content_types = %w[image/png]
        file = fixture_file_upload("sample.svg", "image/svg+xml")

        expect {
          post "/venus_media_library/images.json", params: { file: file }, headers: venus_media_headers(member)
        }.not_to change(ActiveStorage::Blob, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects a disallowed content type" do
        file = fixture_file_upload("sample.png", "application/x-msdownload")

        post "/venus_media_library/images.json", params: { file: file }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects a file whose declared type does not match its contents" do
        file = fixture_file_upload("sample.png", "image/svg+xml")

        post "/venus_media_library/images.json", params: { file: file }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("does not match")
      end

      it "rejects files over the configured byte limit" do
        VenusMediaLibrary.configuration.max_file_size = 1
        file = fixture_file_upload("sample.png", "image/png")

        post "/venus_media_library/images.json", params: { file: file }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("upload limit")
      end

      it "returns an error when no file is provided" do
        post "/venus_media_library/images.json", headers: venus_media_headers(member)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
