module Merchant
  # Every merchant user (owner/manager/staff/cashier) can edit their own name
  # and change their password here.
  class AccountController < BaseController
    def show
      @user = current_user
    end

    # Fresh rotating self-login QR (returns an HTML fragment the profile page
    # swaps in periodically). Encodes a short-lived token for THIS user.
    def quick_login_qr
      token = StaffLogin.encode(current_user, current_workspace)
      url   = merchant_quick_login_url(token: token, host: request.host_with_port)
      render html: helpers.qr_svg(url, size: 180), layout: false
    end

    def update
      @user = current_user
      if params.dig(:user, :password).present?
        ok = @user.update_with_password(password_params)
        bypass_sign_in(@user) if ok # stay signed in after a password change
        notice = "Đã đổi mật khẩu."
      else
        ok = @user.update(name: params.dig(:user, :name))
        notice = "Đã cập nhật tài khoản."
      end

      if ok
        redirect_to merchant_account_path, notice: notice
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:name, :current_password, :password, :password_confirmation)
    end

    def nav_key = :account
  end
end
