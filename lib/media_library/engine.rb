module MediaLibrary
  class Engine < ::Rails::Engine
    isolate_namespace MediaLibrary

    # Make the host-facing picker helper available in the host app's views so
    # apps can call `media_picker_field` without any manual include.
    initializer "media_library.host_helpers" do
      ActiveSupport.on_load(:action_view) do
        include MediaLibrary::PickerHelper
      end
    end

    # Ensure the engine's JS is discoverable by Propshaft/Sprockets in the host.
    initializer "media_library.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/assets/javascripts")
        app.config.assets.precompile += %w[media_library/media_library.js]
      end
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
