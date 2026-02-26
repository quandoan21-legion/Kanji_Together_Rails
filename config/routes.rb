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
    resources :stories, only: [:index, :show, :destroy, :edit, :update] do
      member do
        patch :approve
        put :approve
        patch :reject
        put :reject
      end
    end
  end

  resources :kanji_stories, only: [:index, :new, :create, :edit, :update] do
    collection do
      post :generate_story
    end
  end
end
