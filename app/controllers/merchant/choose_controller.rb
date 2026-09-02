module Merchant
  # Post-login shop picker for owners/staff with more than one workspace.
  # Kept outside Merchant::BaseController so it isn't tenant-scoped or locked.
  class ChooseController < ApplicationController
    layout "auth"
    before_action :authenticate_user!

    def show
      @workspaces = current_user.workspaces.order(:created_at).to_a
      # 0 or 1 shop → no choice to make.
      if @workspaces.size == 1
        redirect_to merchant_url_for(@workspaces.first), allow_other_host: true
      end
    end
  end
end
