require "rails_helper"

# Regression: a picker frame load that is still in flight when an upload
# finishes used to overwrite the grid with the server's pre-upload HTML,
# silently discarding the tile the user had just uploaded. The asset stayed
# saved, but it vanished from the library in front of the editor.
RSpec.describe "media picker upload during a slow frame load", type: :system do
  let!(:member) { Widget.create!(name: "member") }

  before do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")),
      filename: "existing.png", content_type: "image/png"
    )
    VenusMediaLibrary::Asset.create!(blob: blob, owner: member)
  end

  # Issues the picker request immediately (so the server renders the grid from
  # the pre-upload state) but delivers its response late — the ordering that
  # occurs naturally on a cold/slow first load.
  def delay_picker_frame_response(milliseconds)
    page.execute_script(<<~JS)
      window.__mlFrameResponseDelivered = false;
      window.__mlOrigFetch = window.fetch;
      window.fetch = function (url, opts) {
        var response = window.__mlOrigFetch(url, opts);
        if (String(url).indexOf("/picker") === -1) return response;

        return response.then(function (r) {
          return new Promise(function (resolve) {
            setTimeout(function () {
              resolve(r);
              window.__mlFrameResponseDelivered = true;
            }, #{milliseconds});
          });
        });
      };
    JS
  end

  def wait_for_delayed_frame_response
    Timeout.timeout(15) do
      sleep 0.05 until page.evaluate_script("window.__mlFrameResponseDelivered === true")
    end
    # Let the frame's own promise chain (response.text() → innerHTML) settle.
    sleep 1
  end

  it "keeps the uploaded tile when the slower frame response lands after it" do
    visit "/picker_demo"

    # Prime the frame so reopening shows content while the next load is pending.
    click_button "Choose media"
    expect(page).to have_css(".ml-tile", text: "existing.png")
    page.send_keys(:escape)
    expect(page).to have_no_css("#ml-modal.ml-modal--open")

    delay_picker_frame_response(800)

    click_button "Choose media"
    expect(page).to have_css(".ml-tile", text: "existing.png")

    find("#image-upload", visible: :all).set(
      VenusMediaLibrary::Engine.root.join("spec/fixtures/files/sample.png")
    )
    expect(page).to have_css(".ml-tile", count: 2)

    wait_for_delayed_frame_response

    expect(page).to have_css(".ml-tile", count: 2)
  end
end
