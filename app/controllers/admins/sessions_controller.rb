class Admins::SessionsController < Devise::SessionsController
  def create
    if admin_hardcoded_credentials?
      admin = Admin.find_or_create_by!(email: "admin@example.com") do |record|
        record.password = "admin"
        record.password_confirmation = "admin"
      end
      sign_in(:admin, admin)
      redirect_to after_sign_in_path_for(admin)
      return
    end

    super
  end

  private

  # Temporary hardcoded login for admin@gmail.com/admin.
  def admin_hardcoded_credentials?
    email = params.dig(:admin, :email)
    password = params.dig(:admin, :password)
    email == "admin@gmail.com" && password == "admin"
  end
end
