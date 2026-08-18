require "rails_helper"

module VenusMediaLibrary
  # The picker modal is field-aware: it carries the host field's accepted content
  # types (via the `accept` param) and exposes every asset category as a tab that
  # loads into the same Turbo Frame.
  RSpec.describe "Picker modal", type: :request do
    let!(:member) { Widget.create!(name: "member") }
    let!(:admin)  { Widget.create!(name: "admin") }

    around do |example|
      configuration = VenusMediaLibrary.configuration
      original = {
        static: configuration.static_assets,
        cloud: configuration.cloud_assets,
        legacy: configuration.legacy_blob_scope,
        allowed: configuration.allowed_content_types
      }
      configuration.allowed_content_types = %w[image/png image/svg+xml application/pdf]
      configuration.static_assets = -> { [ { filename: "brand.svg", url: "/assets/brand.svg", content_type: "image/svg+xml" } ] }
      configuration.cloud_assets  = -> { [ { filename: "cdn-logo.png", url: "https://cdn.example.test/logo.png", content_type: "image/png" } ] }
      example.run
    ensure
      configuration.static_assets = original[:static]
      configuration.cloud_assets = original[:cloud]
      configuration.legacy_blob_scope = original[:legacy]
      configuration.allowed_content_types = original[:allowed]
    end

    def create_asset(owner: member, filename: "photo.png", content_type: "image/png", community_shared: false)
      fixture = { "application/pdf" => "sample.pdf", "image/svg+xml" => "sample.svg" }.fetch(content_type, "sample.png")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/#{fixture}")),
        filename: filename, content_type: content_type
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: owner, community_shared: community_shared)
    end

    def page_for(body) = Capybara.string(body)

    describe "category tabs" do
      it "renders selectable category tabs for a member (no Legacy)" do
        get "/venus_media_library/picker", params: { target: "field_id" }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        html = page_for(response.body)
        labels = html.all(".ml-tabs__tab").map(&:text)

        expect(labels).to include("Images", "Static", "Cloud", "Community")
        expect(labels).not_to include("Legacy")
      end

      it "exposes the Legacy tab to administrators" do
        get "/venus_media_library/picker", params: { target: "field_id" }, headers: venus_media_headers(admin, admin: true)

        labels = page_for(response.body).all(".ml-tabs__tab").map(&:text)
        expect(labels).to include("Legacy")
      end

      it "keeps the target and accept context on every tab link" do
        get "/venus_media_library/picker", params: { target: "field_id", accept: "image/png" }, headers: venus_media_headers(member)

        community_tab = page_for(response.body).find(".ml-tabs__tab", text: "Community")
        href = community_tab[:href]
        expect(href).to include("category=community")
        expect(href).to include("target=field_id")
        expect(href).to include("accept=image")
      end
    end

    describe "loading a category into the frame" do
      it "defaults to the member's image library" do
        create_asset(filename: "library.png")

        get "/venus_media_library/picker", params: { target: "field_id" }, headers: venus_media_headers(member)

        expect(response.body).to include("library.png")
      end

      it "loads community assets when the community tab is selected" do
        create_asset(owner: Widget.create!(name: "other"), filename: "shared.png", community_shared: true)
        create_asset(owner: Widget.create!(name: "other2"), filename: "private.png")

        get "/venus_media_library/picker", params: { target: "field_id", category: "community" }, headers: venus_media_headers(member)

        expect(response.body).to include("shared.png")
        expect(response.body).not_to include("private.png")
      end

      it "loads host static assets" do
        get "/venus_media_library/picker", params: { target: "field_id", category: "static" }, headers: venus_media_headers(member)

        expect(response.body).to include("brand.svg")
      end

      it "loads host cloud assets" do
        get "/venus_media_library/picker", params: { target: "field_id", category: "cloud" }, headers: venus_media_headers(member)

        expect(response.body).to include("cdn-logo.png")
      end

      it "loads unowned legacy uploads for an admin" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
          filename: "legacy.png", content_type: "image/png"
        )
        VenusMediaLibrary.configuration.legacy_blob_scope = ->(scope) { scope }

        get "/venus_media_library/picker", params: { target: "field_id", category: "legacy" }, headers: venus_media_headers(admin, admin: true)

        expect(response.body).to include(blob.signed_id)
        expect(response.body).to include("legacy.png")
      end
    end

    describe "field-type awareness (selection)" do
      it "disables assets whose type the field does not accept and keeps matching ones selectable" do
        create_asset(filename: "picture.png", content_type: "image/png")
        create_asset(filename: "manual.pdf", content_type: "application/pdf")

        get "/venus_media_library/picker", params: { target: "field_id", accept: "image/png" }, headers: venus_media_headers(member)

        html = page_for(response.body)
        expect(html).to have_css(".ml-tile.ml-tile--disabled[disabled]", text: "manual.pdf")
        expect(html).to have_css(".ml-tile:not([disabled])", text: "picture.png")
      end

      it "sets the upload input accept to the field's declared types" do
        get "/venus_media_library/picker", params: { target: "field_id", accept: "image/png,image/svg+xml" }, headers: venus_media_headers(member)

        expect(page_for(response.body)).to have_css("input[data-ml-upload][accept='image/png,image/svg+xml']", visible: :all)
      end

      it "falls back to the globally allowed types when the field declares nothing" do
        get "/venus_media_library/picker", params: { target: "field_id" }, headers: venus_media_headers(member)

        html = page_for(response.body)
        accept = html.find("input[data-ml-upload]", visible: :all)[:accept]
        expect(accept).to include("image/png")
        expect(accept).to include("application/pdf")
      end
    end
  end
end
