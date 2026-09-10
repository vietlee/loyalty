module Merchant
  class WorkspacesController < BaseController
    def switch
      ws = accessible_workspaces.find { |w| w.id == params[:id].to_i }
      session[:workspace_id] = ws.id if ws
      # Hop to the selected workspace's own subdomain so the dashboard stays there
      # (or the scanner launcher on a phone).
      redirect_to merchant_url_for(ws || current_workspace, merchant_home_path), allow_other_host: true
    end
  end
end
