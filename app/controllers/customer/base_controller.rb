module Customer
  class BaseController < ApplicationController
    include TenantResolver

    layout "member"

    before_action :set_current_workspace
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
