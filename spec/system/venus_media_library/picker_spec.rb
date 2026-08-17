require "rails_helper"

RSpec.describe "media picker", type: :system do
  let!(:member) { Widget.create!(name: "member") }

  before do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
      filename: "existing.png", content_type: "image/png"
    )
    VenusMediaLibrary::Asset.create!(blob: blob, owner: member)
  end

  it "opens, selects an asset, uploads an image, and closes with Escape" do
    visit "/picker_demo"

    click_button "Choose media"
    expect(page).to have_css("#ml-modal.ml-modal--open")
    expect(page).to have_css(".ml-tile", text: "existing.png")

    find(".ml-tile", text: "existing.png").click
    expect(page).to have_field("widget_name", with: %r{/venus_media_library/assets/\d+})
    expect(page).to have_no_css("#ml-modal.ml-modal--open")

    click_button "Choose media"
    expect(page).to have_css(".ml-tile", text: "existing.png")
    attach_file "image-upload", VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png"), make_visible: true
    expect(page).to have_css(".ml-tile", count: 2)

    page.send_keys(:escape)
    expect(page).to have_no_css("#ml-modal.ml-modal--open")
  end
end
