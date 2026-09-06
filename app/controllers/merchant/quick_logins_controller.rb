module Merchant
  # Logs a staff member in via their self-login QR token, then drops them into
  # the mobile counter scanner. Inherits ApplicationController (NOT BaseController)
  # so it does not require an existing session.
  class QuickLoginsController < ApplicationController
    # Opt-in Devise helper so we can set the long-lived remember-me cookie for
    # this passwordless staff QR login (not included in controllers by default).
    include Devise::Controllers::Rememberable

    def create
      user, ws = StaffLogin.resolve(params[:token])
      unless user && ws
        return redirect_to new_user_session_path,
          alert: t("merchant.quick_login.invalid")
      end
      sign_in(:user, user)
      # Keep this device signed in as long as possible: staff scan the QR once
      # and then use the phone as a fixed counter scanner. Devise rememberable
      # is configured for 1 year (config.remember_for) and extends on each use,
      # so the remember cookie re-authenticates even after the session expires.
      remember_me(user)
      session[:workspace_id] = ws.id
      # Land on the minimal staff-mobile launcher (logo + one scanner button),
      # not the full merchant dashboard webview.
      redirect_to merchant_scan_home_path, notice: t("merchant.quick_login.welcome")
    end
  end
end
