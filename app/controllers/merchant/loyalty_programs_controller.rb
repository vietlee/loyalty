module Merchant
  class LoyaltyProgramsController < BaseController
    before_action :require_manager!, only: [:update]

    def show
      @program = current_program
      @program.save! if @program.new_record?
    end

    def update
      @program = current_program
      @program.save! if @program.new_record?
      if @program.update(program_params)
        redirect_to merchant_loyalty_program_path, notice: "Đã lưu cấu hình chương trình."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def nav_key = :program

    def program_params
      params.require(:loyalty_program).permit(
        :points_enabled, :tiers_enabled, :stamps_enabled, :gamification_enabled,
        :earn_points, :earn_per_amount, :currency, :scan_mode, :tier_cycle_months
      )
    end
  end
end
