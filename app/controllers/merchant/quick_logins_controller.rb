module Merchant
  # Logs a staff member in via their self-login QR token, then drops them into
  # the mobile counter scanner. Inherits ApplicationController (NOT BaseController)
  # so it does not require an existing session.
  class QuickLoginsController < ApplicationController
    def create
      user, ws = StaffLogin.resolve(params[:token])
      unless user && ws
        return redirect_to new_user_session_path,
          alert: t("merchant.quick_login.invalid")
      end
      sign_in(:user, user)
      session[:workspace_id] = ws.id
      # Land on the minimal staff-mobile launcher (logo + one scanner button),
      # not the full merchant dashboard webview.
      redirect_to merchant_scan_home_path, notice: t("merchant.quick_login.welcome")
    end
  end
end
