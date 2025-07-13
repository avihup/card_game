Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API routes
  namespace :api do
    namespace :v1 do
      # Game Rules Management
      resources :game_rules do
        member do
          post :activate
          post :deactivate
        end
      end
      
      # Game Session Management
      resources :game_sessions do
        member do
          post :join
          post :start
          post :play_turn
          delete :leave
          post :pause
          post :resume
          post :cancel
        end
      end
      
      # Utility endpoints
      get :health, to: 'health#show'
      post 'game_rules/seed_templates', to: 'game_rules#seed_templates'
    end
  end
  
  # Swagger documentation
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  # Defines the root path route ("/")
  root "rails/health#show"
end
