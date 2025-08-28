Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :debts do
        collection do
          post :import_debts_csv
        end
      end
    end
  end
end
