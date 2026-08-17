MediaLibrary::Engine.routes.draw do
  # Image library: index lists images (HTML grid + JSON), create handles uploads.
  resources :images, only: [ :index, :create ]

  # Turbo Frame that renders the picker modal body for a given target field.
  get "picker", to: "pickers#show", as: :picker

  root to: "images#index"
end
