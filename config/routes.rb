VenusMediaLibrary::Engine.routes.draw do
  # Image library: index lists images (HTML grid + JSON), create handles uploads.
  resources :images, only: [ :index, :create ]
  resources :assets, only: [ :show ] do
    get :thumbnail, on: :member
  end
  resources :legacy_assets, only: [ :index, :show ] do
    get :thumbnail, on: :member
    post :import, on: :member
  end
  resources :static_assets, only: [ :index ]
  resources :community_assets, only: [ :index ]
  resources :cloud_assets, only: [ :index ]
  resource :settings, only: [ :show ], controller: "settings"

  # Turbo Frame that renders the picker modal body for a given target field.
  get "picker", to: "pickers#show", as: :picker

  root to: "images#index"
end
