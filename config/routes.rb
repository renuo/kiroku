# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Slack Events API webhook
  post "slack/events", to: "slack/events#create"

  # Authentication
  get "auth/:provider/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  # Receipts
  resources :receipts, only: %i[index new create edit update destroy] do
    resource :file, only: :show, controller: "receipt_files" do
      get :preview
    end
  end

  # Admin
  namespace :admin do
    resources :receipts, only: %i[index new create edit update destroy] do
      member do
        patch :record
        patch :unrecord
      end
    end
  end

  root "home#index"
end
