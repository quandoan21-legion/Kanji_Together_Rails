Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations]

  # Trang chủ Admin
  root "admin/kanjis#index"

  namespace :admin do
    resources :kanjis do
      member do
        put :approve
        put :reject
      end
    end

    resources :user_kanjis, only: [:index, :edit, :update, :destroy]
    resources :questions
    resources :exams

    # 3. Quản lý Duyệt câu chuyện (Stories)
    resources :stories, only: [:index, :show, :destroy] do
      member do
        # Hỗ trợ cả PUT và PATCH để tránh lỗi form
        patch :approve
        put :approve
        patch :reject
        put :reject
        #ddddgit
      end
    end
  end
end