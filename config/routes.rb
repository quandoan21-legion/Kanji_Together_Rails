Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations]
  root "admin/kanjis#index"

  namespace :admin do
    resources :users
    resources :lessons do
      collection do
        get :search
      end
    end
    resources :courses
    resources :kanjis do
      collection do
        get :search
      end
      member do
        put :approve
        put :reject
      end
    end
    resources :user_kanjis, only: [:index, :edit, :update, :destroy]
    resources :questions
    resources :exams
    resources :stories, only: [:index, :show, :new, :create, :destroy] do
      member do
        patch :approve
        put :approve
        patch :reject
        put :reject
      end
    end
  end
end
