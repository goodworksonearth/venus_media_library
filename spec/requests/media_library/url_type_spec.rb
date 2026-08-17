require "rails_helper"

module MediaLibrary
  # og:image needs an absolute, crawler-fetchable URL. On a private bucket in
  # proxy mode that is the proxy URL (Rails streams the bytes), not the redirect
  # URL. config.url_type = :proxy makes the payload/picker URLs proxy URLs.
  RSpec.describe "image payload url_type", type: :request do
    around do |example|
      original = MediaLibrary.configuration.url_type
      example.run
      MediaLibrary.configuration.url_type = original
    end

    def create_image_blob
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(MediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "og.png",
        content_type: "image/png"
      )
    end

    it "defaults to the redirect URL" do
      create_image_blob
      MediaLibrary.configuration.url_type = :redirect

      get "/media/images.json"

      url = JSON.parse(response.body)["images"].first["url"]
      expect(url).to include("/rails/active_storage/blobs/redirect/")
      expect(url).to match(%r{\Ahttps?://})
    end

    it "returns an absolute proxy URL when url_type is :proxy" do
      create_image_blob
      MediaLibrary.configuration.url_type = :proxy

      get "/media/images.json"

      url = JSON.parse(response.body)["images"].first["url"]
      expect(url).to include("/rails/active_storage/blobs/proxy/")
      expect(url).to match(%r{\Ahttps?://})
    end
  end
end
