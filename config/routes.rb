Rails.application.routes.draw do
  # Trang chủ vào thẳng danh sách Kanji của Admin
  root "admin/kanjis#index"

  # Tất cả chức năng Admin phải nằm trong khối này
  namespace :admin do
    # 1. Quản lý Kanji hệ thống (CRUD đầy đủ)
    # Helper: admin_kanjis_path, new_admin_kanji_path...
    resources :kanjis

    # 2. Quản lý Duyệt Kanji do User đóng góp (MỚI THÊM)
    # Chỉ cần: Xem ds (index), Form duyệt (edit), Duyệt (update), Xóa (destroy)
    # Helper: admin_user_kanjis_path, edit_admin_user_kanji_path...
    resources :user_kanjis, only: [:index, :edit, :update, :destroy]

    # 3. Quản lý Duyệt câu chuyện (Stories)
    resources :stories, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end
end