module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_admin_user!

    helper_method :nav_key

    private

    # Super Admin operates across all tenants — never scope to one workspace.
    def nav_key = nil
  end
end
