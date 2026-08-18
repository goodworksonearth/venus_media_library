require "rails_helper"

module VenusMediaLibrary
  # The value the picker hands back to a URL host field (media_picker_field, e.g.
  # a page's og:image) is the payload `url` — it becomes the STORED value and is
  # fetched later by external crawlers (Facebook/Google/Twitter). It must be an
  # absolute, PUBLIC Active Storage URL, never the admin/owner-gated engine route
  # (/venus_media_library/assets/:id), which a crawler cannot reach.
  RSpec.describe "Picked URL for host URL fields", type: :request do
    let!(:member) { Widget.create!(name: "member") }

    around do |example|
      configuration = VenusMediaLibrary.configuration
      original_url_type = configuration.url_type
      example.run
    ensure
      configuration.url_type = original_url_type
    end

    def create_image_asset(owner: member, filename: "og.png")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: filename, content_type: "image/png"
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: owner)
    end

    def picked_url_for(asset)
      get "/venus_media_library/images.json", headers: venus_media_headers(member)
      expect(response).to have_http_status(:ok)
      JSON.parse(response.body)["images"].find { |image| image["id"] == asset.id }.fetch("url")
    end

    it "delivers an absolute public Active Storage redirect URL by default" do
      asset = create_image_asset

      url = picked_url_for(asset)

      expect(url).to match(%r{\Ahttps?://})
      expect(url).to include("/rails/active_storage/blobs/redirect/")
      expect(url).not_to include("/venus_media_library/assets/")
    end

    it "delivers an absolute public proxy URL when url_type is :proxy" do
      VenusMediaLibrary.configuration.url_type = :proxy
      asset = create_image_asset

      url = picked_url_for(asset)

      expect(url).to match(%r{\Ahttps?://})
      expect(url).to include("/rails/active_storage/blobs/proxy/")
      expect(url).not_to include("/venus_media_library/assets/")
    end

    it "resolves to a URL a crawler can fetch WITHOUT engine auth" do
      asset = create_image_asset

      # No venus_media_headers: an anonymous external crawler.
      url  = picked_url_for(asset)
      path = URI(url).path

      get path # anonymous, no auth headers

      # The public AS route serves (proxy 200) or 302-redirects to storage. It is
      # NOT the engine's owner gate, which answers 401 (no user) / 404 (not owner).
      expect(response).not_to have_http_status(:unauthorized)
      expect(response).not_to have_http_status(:not_found)
      expect(response.status).to satisfy { |status| [ 200, 301, 302 ].include?(status) }
    end
  end
end
