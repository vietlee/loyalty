module Customer
  class ProfileController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
    end

    def update
      @member = current_member
      if @member.update(profile_params)
        redirect_to member_profile_path, notice: t("customer.profile.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:member).permit(:name, :email, :birthday)
    end
  end
end
