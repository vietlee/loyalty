module Merchant
  # Guided first-run setup: brand → mechanics → staff → done.
  class OnboardingController < BaseController
    STEPS = 4

    def show
      @step = clamp_step(params[:step])
      @workspace = current_workspace
      @program   = current_program.tap { |p| p.save! if p.new_record? }
      @presets   = AppearancesController::PRESETS
      @outlets   = current_workspace.outlets.order(:name).to_a
    end

    def update
      @workspace = current_workspace
      step = clamp_step(params[:step])
      case step
      when 1 then save_brand
      when 2 then save_mechanics
      when 3 then invite_staff
      end
      if step >= STEPS
        finish!
      else
        redirect_to merchant_onboarding_path(step: step + 1)
      end
    end

    def skip
      finish!
    end

    private

    def nav_key = nil

    def clamp_step(v) = v.to_i.clamp(1, STEPS).then { |n| n.zero? ? 1 : n }

    def save_brand
      if params[:preset].present? && AppearancesController::PRESETS.key?(params[:preset])
        @workspace.theme = AppearancesController::PRESETS[params[:preset]]["theme"]
      end
      @workspace.branding = (@workspace.branding || {}).merge(
        params.fetch(:branding, {}).permit(:logo_text, :tagline, :customer_term).to_h
      )
      @workspace.save
    end

    def save_mechanics
      current_program.update(program_params)
    end

    def invite_staff
      email = params[:email].to_s.downcase.strip
      return if email.blank?
      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.assign_attributes(name: params[:name].presence || email.split("@").first,
                               password: SecureRandom.hex(12), locale: "vi")
        user.save!
      end
      role = Membership::ROLES.include?(params[:role]) ? params[:role] : "staff"
      current_workspace.memberships.create!(user: user, role: role) unless
        current_workspace.memberships.exists?(user_id: user.id)
    end

    def finish!
      @workspace = current_workspace
      @workspace.update!(settings: @workspace.settings.merge("onboarded" => true))
      redirect_to merchant_root_path, notice: "Thiết lập hoàn tất! Chào mừng đến với bảng điều khiển 🎉"
    end

    def program_params
      params.require(:loyalty_program).permit(:points_enabled, :tiers_enabled, :stamps_enabled,
                                              :gamification_enabled, :earn_points, :earn_per_amount, :scan_mode)
    end
  end
end
