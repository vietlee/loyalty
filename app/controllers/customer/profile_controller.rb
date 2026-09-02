module Customer
  class ProfileController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
    end

    def update
      current_member.update(profile_params)
      redirect_to member_profile_path, notice: "Đã cập nhật thông tin."
    end

    private

    def profile_params
      params.require(:member).permit(:name, :birthday)
    end
  end
end
