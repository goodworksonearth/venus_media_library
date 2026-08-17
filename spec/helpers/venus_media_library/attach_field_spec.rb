require "rails_helper"

module VenusMediaLibrary
  # Attach mode: instead of writing a URL into a text field, the picker writes the
  # chosen blob's signed_id into a hidden field NAMED FOR THE ATTACHMENT
  # (e.g. widget[cover]) so Active Storage attaches it on save.
  RSpec.describe PickerHelper, type: :helper do
    let(:widget) { Widget.new }

    let(:form) do
      ActionView::Helpers::FormBuilder.new(:widget, widget, helper, {})
    end

    it "renders a hidden field named for the attachment carrying the signed_id" do
      html = helper.media_attach_field(form, :cover)

      expect(html).to include('name="widget[cover]"')
      expect(html).to include('data-ml-signed-id-for="widget_cover"')
    end

    it "disables the hidden attachment field until an image is picked" do
      # An empty string submitted for a has_one_attached DETACHES the current file.
      # Disabling the field keeps it out of the params until JS sets a signed_id
      # (and flips disabled off) on selection, so saving without picking is a no-op.
      html = helper.media_attach_field(form, :cover)

      hidden = html[/<input[^>]*data-ml-signed-id-for="widget_cover"[^>]*>/]
      expect(hidden).to be_present
      expect(hidden).to include("disabled")
    end

    it "renders a read-only preview input and the picker button for the field" do
      html = helper.media_attach_field(form, :cover, label: "Pick a cover")

      expect(html).to include('id="widget_cover"')
      expect(html).to include("Pick a cover")
      expect(html).to include('data-ml-open="true"')
      expect(html).to include('data-ml-target="widget_cover"')
      expect(html).to include("/venus_media_library/picker")
    end

    it "renders the shared modal shell only once per page" do
      first  = helper.media_attach_field(form, :cover)
      second = helper.media_attach_field(form, :cover)

      expect(first.scan("ml-modal__dialog").size).to eq(1)
      expect(second.scan("ml-modal__dialog").size).to eq(0)
    end
  end
end
