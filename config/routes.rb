Rails.application.routes.draw do

  get 'ai_interactions/chat', to: 'ai_interactions#chat', as: :ai_chat
  post 'ai_interactions/project/:project_id', to: 'ai_interactions#create_chat_by_project', as: :ai_chat_project
  get 'ai_interactions/project/:project_id', to: 'ai_interactions#chat_by_project', as: :ai_chat_by_project


  get 'ai_interactions/chat_history', to: 'ai_interactions#chat_history', as: :ai_chat_history


  root 'dashboard#index'
  get "dashboard/index"

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
