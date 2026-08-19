require "rails_helper"

# End-to-end proof that the picker is field-aware: opened for an image-only
# field, a PDF asset is greyed out and cannot be returned to the field, while an
# image can. Also confirms the category tabs render inside the modal.
RSpec.describe "field-aware media picker", type: :system do
  let!(:member) { Widget.create!(name: "member") }

  around do |example|
    original = VenusMediaLibrary.configuration.allowed_content_types
    VenusMediaLibrary.configuration.allowed_content_types += [ "application/pdf" ]
    example.run
  ensure
    VenusMediaLibrary.configuration.allowed_content_types = original
  end

  before do
    { "picture.png" => "image/png", "manual.pdf" => "application/pdf" }.each do |filename, content_type|
      fixture = content_type == "application/pdf" ? "sample.pdf" : "sample.png"
      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/#{fixture}")),
        filename: filename, content_type: content_type
      )
      VenusMediaLibrary::Asset.create!(blob: blob, owner: member)
    end
  end

  it "greys out disallowed assets and only lets a matching one be picked" do
    visit "/picker_demo"

    click_button "Choose image only"
    expect(page).to have_css("#ml-modal.ml-modal--open")

    # Category tabs are present in the modal.
    expect(page).to have_css(".ml-picker__tabs .ml-tabs__tab", text: "Community")

    # The PDF is greyed out and disabled, so the browser cannot pick it.
    expect(page).to have_css(".ml-tile.ml-tile--disabled[disabled]", text: "manual.pdf")

    # The image is selectable and writes its PUBLIC Active Storage URL into the
    # image-only field (the crawler-fetchable value a host stores as og:image),
    # not the owner-gated engine asset route.
    find(".ml-tile:not([disabled])", text: "picture.png").click
    expect(page).to have_no_css("#ml-modal.ml-modal--open")
    expect(page).to have_field("img_only_name", with: %r{/rails/active_storage/blobs/redirect/})
  end
end
