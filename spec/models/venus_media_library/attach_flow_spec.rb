require "rails_helper"

module VenusMediaLibrary
  # The signed_id flow attach mode relies on: a has_one_attached association
  # accepts a blob's signed_id and attaches THAT blob on save. This is the
  # contract media_attach_field depends on.
  RSpec.describe "attach mode signed_id flow", type: :model do
    def create_image_blob
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
        filename: "picked.png",
        content_type: "image/png"
      )
    end

    it "attaches the picked blob when its signed_id is assigned" do
      blob   = create_image_blob
      widget = Widget.create!(name: "brochure")

      widget.cover = blob.signed_id
      widget.save!

      expect(widget.reload.cover).to be_attached
      expect(widget.cover.blob).to eq(blob)
    end
  end
end
