module VenusMediaLibrary
  class ApplicationController < ActionController::Base
    # Run the host-configured access gate (if any) before every engine action.
    # The engine ships open; the host restricts the picker/upload endpoints by
    # setting VenusMediaLibrary.configuration.authenticate_with to a proc.
    before_action :authenticate_venus_media_library_access!

    private

    def authenticate_venus_media_library_access!
      gate = VenusMediaLibrary.configuration.authenticate_with
      return unless gate.respond_to?(:call)

      # instance_exec so the proc runs in this controller's context and can use
      # host helpers (current_user, redirect_to, head, main_app, ...).
      instance_exec(&gate)
    end
  end
end
