require "rails_helper"

module VenusMediaLibrary
  RSpec.describe PickerHelper, type: :helper do
    let(:object) do
      Struct.new(:og_image, :og_image_signed_id).new("https://cdn.example.com/old.png", nil)
    end

    let(:form) do
      ActionView::Helpers::FormBuilder.new(:page, object, helper, {})
    end

    it "renders a text input pre-filled with the current field value" do
      html = helper.media_picker_field(form, :og_image)

      expect(html).to include('id="page_og_image"')
      expect(html).to include("https://cdn.example.com/old.png")
      expect(html).to include('class="ml-field__input"')
    end

    it "renders a button wired to open the picker for that field" do
      html = helper.media_picker_field(form, :og_image, label: "Pick image")

      expect(html).to include("Pick image")
      expect(html).to include('data-ml-open="true"')
      expect(html).to include('data-ml-target="page_og_image"')
      expect(html).to include("/venus_media_library/picker")
      expect(html).to include("target=page_og_image").or include("target%3Dpage_og_image").or include("page_og_image")
    end

    it "renders a hidden signed-id companion input by default" do
      html = helper.media_picker_field(form, :og_image)

      expect(html).to include('name="page[og_image_signed_id]"')
      expect(html).to include('data-ml-signed-id-for="page_og_image"')
    end

    it "can skip the signed-id field" do
      html = helper.media_picker_field(form, :og_image, signed_id_field: false)

      expect(html).not_to include("signed_id")
    end

    it "renders the shared modal shell only once per page" do
      first  = helper.media_picker_field(form, :og_image)
      second = helper.media_picker_field(form, :og_image)

      expect(first.scan("ml-modal__dialog").size).to eq(1)
      expect(second.scan("ml-modal__dialog").size).to eq(0)
    end
  end
end
