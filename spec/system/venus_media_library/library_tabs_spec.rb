require "rails_helper"

RSpec.describe "media library left navigation", type: :system do
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

  it "navigates private, community, static, and cloud views from the left sidebar" do
    visit "/venus_media_library"

    # Full page uses the left-nav management shell, not the horizontal tab bar.
    expect(page).to have_css(".ml-layout__nav .ml-nav")
    expect(page).to have_no_css(".ml-tabs")
    expect(page).to have_css(".ml-nav__link[aria-current='page']", text: "My Library")

    within(".ml-nav") { click_link "Community" }
    expect(page).to have_css("h1", text: "Community Assets")
    expect(page).to have_css(".ml-nav__link[aria-current='page']", text: "Community")

    within(".ml-nav") { click_link "Static Assets" }
    expect(page).to have_css("h1", text: "Static Assets")
    expect(page).to have_content("brand.svg")
    expect(page).to have_css(".ml-nav__link[aria-current='page']", text: "Static Assets")

    within(".ml-nav") { click_link "Cloud Assets" }
    expect(page).to have_css("h1", text: "Cloud Assets")
    expect(page).to have_content("cdn-logo.svg")
    expect(page).to have_css(".ml-nav__link[aria-current='page']", text: "Cloud Assets")
  end
end
