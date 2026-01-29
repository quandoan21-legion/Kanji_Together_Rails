Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations]
  root "admin/kanjis#index"

  namespace :admin do
    resources :users
    resources :lessons
    resources :kanjis do
      member do
        put :approve
        put :reject
      end
    end
    resources :user_kanjis, only: [:index, :edit, :update, :destroy]
    resources :questions
    resources :exams
    resources :stories, only: [:index, :show, :destroy] do
      member do
        patch :approve
        put :approve
        patch :reject
        put :reject
      end
    end
  end
end