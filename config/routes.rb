Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  namespace :api do
    namespace :v1 do
      resources :debts do
        collection do
          post :import_debts_csv
          post :generate_invoices
          post :webhook_payment
        end
      end
    end
  end
end
