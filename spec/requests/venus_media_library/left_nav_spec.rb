require "rails_helper"

module VenusMediaLibrary
  # The full-page media library (/venus_media_library, i.e. "/media" in the host)
  # is the management workspace: a 30% left-nav column beside a 70% content
  # column. The picker modal stays lean and keeps its own horizontal tabs, so the
  # left-nav sidebar must never leak into that Turbo Frame path.
  RSpec.describe "Full-page left navigation", type: :request do
    let!(:member) { Widget.create!(name: "member") }
    let!(:admin)  { Widget.create!(name: "admin") }

    def page_for(body)
      Capybara.string(body)
    end

    describe "GET /venus_media_library (full page)" do
      it "renders the 30/70 left-nav management shell instead of horizontal tabs" do
        get "/venus_media_library", headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        html = page_for(response.body)

        # Two-column management shell: a left navigation column and a content column.
        expect(html).to have_css(".ml-layout")
        expect(html).to have_css(".ml-layout__nav .ml-nav")
        expect(html).to have_css(".ml-layout__content")

        # The horizontal tab bar is not the primary nav on the full page anymore.
        expect(html).not_to have_css(".ml-tabs")

        # The category grid still renders inside the content column.
        expect(html).to have_css(".ml-layout__content .ml-library")
      end

      it "lists the non-admin destinations vertically and marks the active one" do
        get "/venus_media_library", headers: venus_media_headers(member)

        html = page_for(response.body)
        labels = html.all(".ml-nav__link").map(&:text)

        expect(labels).to include("My Library", "Static Assets", "Cloud Assets", "Community")
        expect(html).to have_css(".ml-nav__link[aria-current='page']", text: "My Library")
      end

      it "hides admin-only destinations (Legacy, Settings) from non-admins" do
        get "/venus_media_library", headers: venus_media_headers(member)

        html = page_for(response.body)
        labels = html.all(".ml-nav__link").map(&:text)

        expect(labels).not_to include("Settings")
        expect(labels).not_to include("Legacy Assets")
      end

      it "shows admin-only destinations to administrators" do
        get "/venus_media_library", headers: venus_media_headers(admin, admin: true)

        html = page_for(response.body)
        labels = html.all(".ml-nav__link").map(&:text)

        expect(labels).to include("Legacy Assets", "Settings")
      end
    end

    describe "active-section highlighting across destinations" do
      it "marks Community active on the community page" do
        get "/venus_media_library/community_assets", headers: venus_media_headers(member)

        expect(page_for(response.body)).to have_css(".ml-nav__link[aria-current='page']", text: "Community")
      end

      it "marks Settings active on the settings page for an admin" do
        get "/venus_media_library/settings", headers: venus_media_headers(admin, admin: true)

        expect(page_for(response.body)).to have_css(".ml-nav__link[aria-current='page']", text: "Settings")
      end
    end

    describe "modal picker path stays lean" do
      it "renders the horizontal tabs component, not the left-nav sidebar" do
        get "/venus_media_library/picker", params: { target: "field_id" }, headers: venus_media_headers(member)

        expect(response).to have_http_status(:ok)
        html = page_for(response.body)

        # The picker Turbo Frame (layout: false) is the modal body: no full-page
        # left-nav shell.
        expect(html).not_to have_css(".ml-layout")
        expect(html).not_to have_css(".ml-nav")
      end
    end
  end
end
