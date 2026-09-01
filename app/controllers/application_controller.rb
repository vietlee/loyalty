class ApplicationController < ActionController::Base
  include Pundit::Authorization

  layout :layout_by_resource
  before_action :set_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :merchant_url_for, :customer_url_for, :workspace_host

  # Base platform host (no subdomain), e.g. "loyalty.czin.net".
  PLATFORM_HOST = ENV.fetch("PLATFORM_HOST", "loyalty.czin.net")

  private

  # Merchants work inside their own workspace subdomain. Land the owner there
  # right after sign-in so every relative link in the dashboard stays on the
  # subdomain (and off the shared main domain).
  def after_sign_in_path_for(resource)
    case resource
    when AdminUser
      admin_root_path
    when User
      ws = resource.workspaces.find_by(id: session[:workspace_id]) ||
           resource.workspaces.order(:created_at).first
      stored = stored_location_for(:user)
      path = stored.presence ? URI(stored).request_uri : "/merchant"
      merchant_url_for(ws, path)
    else
      super
    end
  end

  # Whether to emit absolute subdomain URLs. Only in production, where the
  # wildcard cert + shared session cookie make cross-subdomain hops seamless;
  # dev/test stay on a single host via /w/:slug and /merchant paths.
  def force_subdomain_links? = Rails.env.production?

  def workspace_host(workspace) = "#{workspace.subdomain}.#{PLATFORM_HOST}"

  # URL to a workspace's merchant dashboard, preferring the workspace subdomain.
  def merchant_url_for(workspace, path = "/merchant")
    return path unless force_subdomain_links? && workspace&.subdomain.present?
    "https://#{workspace_host(workspace)}#{path}"
  end

  # URL to a workspace's customer PWA.
  def customer_url_for(workspace, path = "/")
    return "#" unless workspace
    if force_subdomain_links? && workspace.subdomain.present?
      "https://#{workspace_host(workspace)}#{path}"
    else
      "/w/#{workspace.slug}#{path == '/' ? '' : path}"
    end
  end

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
