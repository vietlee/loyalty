module Merchant
  class ScannerController < BaseController
    def show
      @tab = %w[earn redeem pos].include?(params[:tab]) ? params[:tab] : "earn"
      # Owner/manager can switch the active branch for this session.
      if params[:outlet].present? && selectable_outlets.any? { |o| o.id.to_s == params[:outlet].to_s }
        session[:active_outlet_id] = params[:outlet]
      end
    end

    private

    def nav_key = :scanner
  end
end
