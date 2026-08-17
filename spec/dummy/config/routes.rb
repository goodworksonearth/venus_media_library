Rails.application.routes.draw do
  mount VenusMediaLibrary::Engine => "/media"
end
