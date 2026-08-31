module Merchant
  class WorkspacesController < BaseController
    def switch
      ws = accessible_workspaces.find { |w| w.id == params[:id].to_i }
      session[:workspace_id] = ws.id if ws
      redirect_to merchant_root_path
    end
  end
end
