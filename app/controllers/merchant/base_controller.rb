module Merchant
  class BaseController < ApplicationController
    layout "merchant"

    before_action :authenticate_user!
    before_action :set_current_workspace
    around_action :scope_tenant

    helper_method :current_workspace, :accessible_workspaces,
                  :current_membership, :current_program, :nav_key

    private

    def accessible_workspaces
      @accessible_workspaces ||= current_user ? current_user.workspaces.order(:created_at).to_a : []
    end

    def current_workspace = @current_workspace

    def set_current_workspace
      return unless current_user
      # The shop subdomain (or custom domain) is authoritative when the owner
      # can access that workspace — so cozycafe.loyalty.czin.net/merchant always
      # manages Cozy Cafe, regardless of any stale session selection.
      host_ws = workspace_from_host
      if host_ws && accessible_workspaces.any? { |w| w.id == host_ws.id }
        @current_workspace = host_ws
      elsif session[:workspace_id].present?
        @current_workspace = accessible_workspaces.find { |w| w.id == session[:workspace_id].to_i }
      end
      @current_workspace ||= accessible_workspaces.first
      session[:workspace_id] = @current_workspace&.id
    end

    def workspace_from_host
      sub = request.subdomains.first
      unless sub.blank? || TenantResolver::RESERVED_SUBDOMAINS.include?(sub)
        ws = Workspace.find_by(subdomain: sub)
      end
      ws || Workspace.find_by(custom_domain: request.host)
    end

    def scope_tenant
      if @current_workspace
        ActsAsTenant.with_tenant(@current_workspace) { yield }
      else
        yield
      end
    end

    def current_membership
      return nil unless current_user && current_workspace
      @current_membership ||= current_user.membership_for(current_workspace)
    end

    def current_program
      @current_program ||= current_workspace&.program
    end

    def require_manager!
      redirect_to merchant_root_path, alert: "Chỉ chủ cửa hàng/quản lý mới có quyền." unless current_membership&.can_manage?
    end

    # Overridden per controller to highlight the active sidebar item.
    def nav_key = nil
  end
end
