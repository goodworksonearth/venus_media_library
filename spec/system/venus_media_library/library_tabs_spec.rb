require "rails_helper"

RSpec.describe "media library tabs", type: :system do
  let!(:member) { Widget.create!(name: "member") }

  around do |example|
    configuration = VenusMediaLibrary.configuration
    original_static_assets = configuration.static_assets
    original_cloud_assets = configuration.cloud_assets
    configuration.static_assets = -> { [ { filename: "brand.svg", url: "/assets/brand.svg", content_type: "image/svg+xml" } ] }
    configuration.cloud_assets = -> { [ { filename: "cdn-logo.svg", url: "https://cdn.example.test/logo.svg", content_type: "image/svg+xml" } ] }
    example.run
  ensure
    configuration.static_assets = original_static_assets
    configuration.cloud_assets = original_cloud_assets
  end

  it "navigates between private, community, static, and cloud asset views" do
    visit "/venus_media_library"

    expect(page).to have_css(".ml-tabs__tab[aria-current='page']", text: "My Library")
    click_link "Community"
    expect(page).to have_css("h1", text: "Community Assets")
    expect(page).to have_css(".ml-tabs__tab[aria-current='page']", text: "Community")

    click_link "Static Assets"
    expect(page).to have_css("h1", text: "Static Assets")
    expect(page).to have_content("brand.svg")
    expect(page).to have_css(".ml-tabs__tab[aria-current='page']", text: "Static Assets")

    click_link "Cloud Assets"
    expect(page).to have_css("h1", text: "Cloud Assets")
    expect(page).to have_content("cdn-logo.svg")
    expect(page).to have_css(".ml-tabs__tab[aria-current='page']", text: "Cloud Assets")
  end
end
