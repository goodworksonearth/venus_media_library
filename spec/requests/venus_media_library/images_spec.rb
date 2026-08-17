require "rails_helper"

module VenusMediaLibrary
  RSpec.describe "Images", type: :request do
    def create_image_blob(filename: "existing.png", content_type: "image/png")
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: filename,
        content_type: content_type
      )
    end

    def create_non_image_blob
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("hello"),
        filename: "notes.txt",
        content_type: "text/plain"
      )
    end

    describe "GET /media/images" do
      it "returns image blobs as JSON, newest first" do
        old = create_image_blob(filename: "old.png")
        new = create_image_blob(filename: "new.png")
        create_non_image_blob # should be excluded

        get "/media/images.json"

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        ids = body["images"].map { |i| i["id"] }

        expect(ids).to include(old.id, new.id)
        expect(body["images"].map { |i| i["filename"] }).not_to include("notes.txt")
        # newest first
        expect(ids.index(new.id)).to be < ids.index(old.id)
        expect(body["images"].first).to include("signed_id", "url", "thumb_url")
      end

      it "renders an HTML grid" do
        create_image_blob(filename: "grid.png")

        get "/media/images"

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ml-grid")
        expect(response.body).to include("grid.png")
      end

      it "paginates" do
        get "/media/images.json", params: { page: 2, per_page: 1 }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["page"]).to eq(2)
      end
    end

    describe "POST /media/images" do
      it "uploads a file and stores an Active Storage blob" do
        file = fixture_file_upload("sample.png", "image/png")

        expect {
          post "/media/images.json", params: { file: file }
        }.to change(ActiveStorage::Blob, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["filename"]).to eq("sample.png")
        expect(body["content_type"]).to eq("image/png")
        expect(body["signed_id"]).to be_present

        blob = ActiveStorage::Blob.find(body["id"])
        expect(blob.download.bytesize).to eq(File.size(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")))
      end

      it "rejects a disallowed content type" do
        file = fixture_file_upload("sample.png", "application/x-msdownload")

        expect {
          post "/media/images.json", params: { file: file }
        }.not_to change(ActiveStorage::Blob, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to be_present
      end

      it "returns an error when no file is provided" do
        post "/media/images.json"
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
