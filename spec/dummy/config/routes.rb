Rails.application.routes.draw do
  get "picker_demo", to: "picker_demos#show"
  mount VenusMediaLibrary::Engine => "/venus_media_library"
end
