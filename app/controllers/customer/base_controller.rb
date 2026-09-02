module Customer
  class BaseController < ApplicationController
    include TenantResolver

    layout "member"

    before_action :set_current_workspace
    before_action :enforce_workspace_access
    before_action -> { no_browser_cache if member_signed_in? }
    around_action :scope_tenant
    helper_method :current_workspace, :current_program

    private

    def set_current_workspace
      @current_workspace = resolve_workspace
    end

    def scope_tenant
      if @current_workspace
        ActsAsTenant.with_tenant(@current_workspace) { yield }
      else
        yield
      end
    end

    # A suspended / long-unpaid shop's customer app is turned off too.
    def enforce_workspace_access
      return unless @current_workspace&.access_blocked?
      render "customer/shared/unavailable", layout: "member", status: :forbidden
    end

    def current_workspace = @current_workspace

    def current_program
      @current_program ||= current_workspace&.program
    end

    # Non-home controllers need a resolved shop.
    def require_workspace!
      redirect_to root_path, alert: "Vui lòng chọn cửa hàng." unless current_workspace
    end

    def require_member!
      return if member_signed_in? && current_member&.workspace_id == current_workspace&.id
      redirect_to member_login_path
    end

    # Keep /w/:slug in generated URLs only when we arrived via the path fallback.
    def default_url_options
      params[:workspace_slug].present? ? { workspace_slug: params[:workspace_slug] } : {}
    end
  end
end
