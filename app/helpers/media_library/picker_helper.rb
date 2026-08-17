module MediaLibrary
  # Host-facing helper. Included into the host app's views by the engine (see
  # MediaLibrary::Engine), so apps can drop the picker next to any URL field.
  #
  #   <%= form_with model: @page do |f| %>
  #     <%= media_picker_field f, :og_image %>
  #   <% end %>
  #
  # Renders a text input (the field the host already had) plus a "Choose from
  # library" button wired to open the modal. Selecting an image writes its URL
  # into the input; a hidden `<field>_signed_id` input also receives the blob's
  # signed id so the host can attach it if desired.
  module PickerHelper
    # form  - a form builder (form_with / form_for)
    # field - the attribute holding the image URL (e.g. :og_image)
    # opts:
    #   :label            - button label (default "Choose from library")
    #   :placeholder      - text input placeholder
    #   :signed_id_field  - name for the hidden signed-id input
    #                       (default "<field>_signed_id"); pass false to skip
    #   :input_html       - extra HTML options merged into the text input
    #   :class            - wrapper CSS class
    def media_picker_field(form, field, **opts)
      input_id  = "#{form.object_name}_#{field}".parameterize.tr("-", "_")
      label     = opts.fetch(:label, "Choose from library")
      wrapper   = opts.fetch(:class, "ml-field")
      input_html = {
        id:    input_id,
        class: "ml-field__input",
        placeholder: opts[:placeholder]
      }.merge(opts[:input_html] || {})

      signed_id_field = opts.fetch(:signed_id_field, "#{field}_signed_id")

      # Endpoint the JS uses to load the picker frame for this field.
      picker_src = media_library.picker_path(target: input_id)

      content_tag(:div, class: wrapper, data: { ml_field: input_id }) do
        parts = []
        parts << form.text_field(field, input_html)

        if signed_id_field
          hidden_id = "#{input_id}_signed_id"
          parts << form.hidden_field(signed_id_field, id: hidden_id, data: { ml_signed_id_for: input_id })
        end

        parts << button_tag(label,
          type: "button",
          class: "ml-btn ml-btn--primary ml-field__button",
          data: { ml_open: true, ml_target: input_id, ml_src: picker_src })

        safe_join(parts)
      end + media_library_modal_shell
    end

    # Renders the shared modal shell once per page. The picker frame is lazy
    # loaded into it when a button is clicked.
    def media_library_modal_shell
      return "".html_safe if @_media_library_modal_rendered

      @_media_library_modal_rendered = true
      render partial: "media_library/pickers/modal"
    end
  end
end
