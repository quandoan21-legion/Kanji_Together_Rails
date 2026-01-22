Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations]
  root "admin/kanjis#index"

  namespace :admin do
    # 1. Quản lý Kanji hệ thống
    resources :kanjis

    # 2. Quản lý Duyệt Kanji (Dành cho bản ghi KanjiCharacters thô)
    resources :user_kanjis, only: [:index, :edit, :update, :destroy]
    # Resources tự động tạo 7 routes chuẩn RESTful (index, new, create, show, edit, update, destroy)
    resources :questions
    # 3. Quản lý Duyệt câu chuyện (Stories)
    resources :stories, only: [:index, :show, :destroy] do
      member do
        # Sửa: Dùng cả patch và put cho reject để tránh lỗi lệch Method giữa View và Controller
        patch :approve
        put :approve
        patch :reject
        put :reject
      end
    end
  end
end