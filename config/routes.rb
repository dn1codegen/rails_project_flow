Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "projects#index"

  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resource :profile, only: %i[show edit update]
  get "shared/projects/:token", to: "shared_projects#show", as: :shared_project

  resources :projects do
    collection do
      get :archive
    end

    member do
      post :refresh_share_link
    end

    resources :project_changes, only: :create
  end
end
