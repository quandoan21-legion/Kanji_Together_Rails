Rails.application.routes.draw do
  namespace :admin do
    resources :kanjis
  end
  root "admin/kanjis#index"
end