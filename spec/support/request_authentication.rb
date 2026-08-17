RSpec.configure do |config|
  config.around(type: :request) do |example|
    configuration = VenusMediaLibrary.configuration
    original_current_user = configuration.current_user
    original_admin = configuration.admin

    configuration.current_user = lambda do
      Widget.find_by(id: request.headers["X-Venus-Media-User-ID"])
    end
    configuration.admin = lambda do |_user|
      request.headers["X-Venus-Media-Admin"] == "true"
    end

    example.run
  ensure
    configuration.current_user = original_current_user
    configuration.admin = original_admin
  end
end

def venus_media_headers(user, admin: false)
  {
    "X-Venus-Media-User-ID" => user.id.to_s,
    "X-Venus-Media-Admin" => admin.to_s
  }
end
