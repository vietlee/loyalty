module Merchant
  class StaffController < BaseController
    before_action :require_manager!, except: [:index]

    def index
      @memberships = current_workspace.memberships.includes(:user, :outlet).to_a
      @outlets = current_workspace.outlets.order(:name).to_a
    end

    # Invite a staff member by email (creates the user if new + a membership).
    def create
      email = params[:email].to_s.downcase.strip
      name  = params[:name].presence || email.split("@").first
      role  = Membership::ROLES.include?(params[:role]) ? params[:role] : "staff"

      if email.blank?
        return redirect_to merchant_staff_index_path, alert: "Vui lòng nhập email."
      end

      user = User.find_or_initialize_by(email: email)
      if user.new_record?
        user.assign_attributes(name: name, password: SecureRandom.hex(12), locale: "vi")
        user.save!
      end
      if current_workspace.memberships.exists?(user_id: user.id)
        redirect_to merchant_staff_index_path, alert: "Nhân viên này đã có trong workspace."
      else
        current_workspace.memberships.create!(user: user, role: role, outlet_id: params[:outlet_id].presence)
        redirect_to merchant_staff_index_path, notice: "Đã mời #{name} (#{role})."
      end
    end

    def update
      m = current_workspace.memberships.find(params[:id])
      m.update(role: params[:role], outlet_id: params[:outlet_id].presence) if Membership::ROLES.include?(params[:role])
      redirect_to merchant_staff_index_path, notice: "Đã cập nhật phân quyền."
    end

    def destroy
      m = current_workspace.memberships.find(params[:id])
      if m.owner? && current_workspace.memberships.where(role: "owner").count <= 1
        redirect_to merchant_staff_index_path, alert: "Không thể xoá chủ cửa hàng duy nhất."
      else
        m.destroy
        redirect_to merchant_staff_index_path, notice: "Đã gỡ nhân viên."
      end
    end

    private

    def nav_key = :staff
  end
end
