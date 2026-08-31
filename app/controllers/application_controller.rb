class ApplicationController < ActionController::Base
  include Pundit::Authorization

  layout :layout_by_resource
  before_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def layout_by_resource
    devise_controller? ? "auth" : "application"
  end

  def set_locale
    I18n.locale = resolve_locale
  end

  def resolve_locale
    requested = params[:locale] || session[:locale]
    return requested.to_sym if requested && I18n.available_locales.map(&:to_s).include?(requested.to_s)

    if respond_to?(:current_member) && current_member
      current_member.locale.to_sym
    elsif respond_to?(:current_user) && current_user
      current_user.display_locale.to_sym
    else
      I18n.default_locale
    end
  end

  def user_not_authorized
    flash[:alert] = t("errors.not_authorized", default: "Bạn không có quyền thực hiện thao tác này.")
    redirect_back fallback_location: main_app.root_path
  end
end
