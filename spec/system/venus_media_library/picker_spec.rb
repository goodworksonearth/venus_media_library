require "rails_helper"

RSpec.describe "media picker", type: :system do
  let!(:member) { Widget.create!(name: "member") }

  around do |example|
    original_content_types = VenusMediaLibrary.configuration.allowed_content_types
    VenusMediaLibrary.configuration.allowed_content_types += [ "application/pdf" ]
    example.run
  ensure
    VenusMediaLibrary.configuration.allowed_content_types = original_content_types
  end

  before do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
      filename: "existing.png", content_type: "image/png"
    )
    VenusMediaLibrary::Asset.create!(blob: blob, owner: member)
  end

  it "opens, selects media, uploads an image and PDF, and closes with Escape" do
    visit "/picker_demo"

    click_button "Choose media"
    expect(page).to have_css("#ml-modal.ml-modal--open")
    expect(page).to have_css(".ml-tile", text: "existing.png")

    find(".ml-tile", text: "existing.png").click
    expect(page).to have_field("widget_name", with: %r{/venus_media_library/assets/\d+})
    expect(page).to have_no_css("#ml-modal.ml-modal--open")

    click_button "Choose media"
    expect(page).to have_css(".ml-tile", text: "existing.png")
    find("#image-upload", visible: :all).set(
      VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")
    )
    expect(page).to have_css(".ml-tile", count: 2)

    find("#image-upload", visible: :all).set(
      VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.pdf")
    )
    expect(page).to have_css(".ml-tile", text: "sample.pdf")
    expect(page).to have_css(".ml-tile__document", text: "PDF")

    page.send_keys(:escape)
    expect(page).to have_no_css("#ml-modal.ml-modal--open")
  end
end
