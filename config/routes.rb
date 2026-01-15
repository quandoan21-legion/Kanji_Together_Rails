Rails.application.routes.draw do
  # Trang chủ vào thẳng danh sách Kanji của Admin
  root "admin/kanjis#index"

  # Tất cả chức năng Admin phải nằm trong khối này
  namespace :admin do
    # Helper sẽ là: admin_kanjis_path, new_admin_kanji_path...
    resources :kanjis

    resources :stories, only: [:index, :show] do
      member do
        patch :approve
        patch :reject
      end
    end
  end
end