module Merchant
  class ScannerController < BaseController
    def show
      @tab = %w[earn redeem pos].include?(params[:tab]) ? params[:tab] : "earn"
    end

    private

    def nav_key = :scanner
  end
end
