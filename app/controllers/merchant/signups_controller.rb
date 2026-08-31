module Merchant
  # Public self-serve merchant registration. Creates a workspace (its own
  # subdomain), an owner, and default loyalty config, then signs the owner in.
  class SignupsController < ApplicationController
    layout "auth"

    RESERVED = TenantResolver::RESERVED_SUBDOMAINS

    def new
      redirect_to(merchant_root_path) and return if user_signed_in?
      @workspace = Workspace.new(industry: "fnb")
    end

    def create
      @workspace = Workspace.new(workspace_params)
      @workspace.status = "pending"      # goes to the Super Admin approval queue
      @workspace.plan   = "starter"
      @workspace.theme  = AppearancesController::PRESETS.dig(preset_for(@workspace.industry), "theme") || {}
      @email = params[:email].to_s.downcase.strip
      @name  = params[:owner_name].presence || "Chủ cửa hàng"

      if reserved_subdomain?
        @workspace.errors.add(:subdomain, "không sử dụng được, vui lòng chọn tên khác")
        return render :new, status: :unprocessable_entity
      end
      unless valid_signup?
        return render :new, status: :unprocessable_entity
      end

      ActiveRecord::Base.transaction do
        @workspace.save!
        owner = User.find_or_initialize_by(email: @email)
        if owner.new_record?
          owner.assign_attributes(name: @name, password: params[:password], locale: "vi")
          owner.save!
        end
        ActsAsTenant.with_tenant(@workspace) do
          @workspace.memberships.create!(user: owner, role: "owner")
        end
        WorkspaceBootstrap.call(@workspace)
        sign_in(:user, owner)
        session[:workspace_id] = @workspace.id
      end
      redirect_to merchant_root_path, notice: "Chào mừng! Workspace của bạn đang chờ duyệt — bạn vẫn có thể thiết lập ngay."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    private

    def workspace_params
      params.require(:workspace).permit(:name, :subdomain, :industry)
    end

    def reserved_subdomain?
      RESERVED.include?(@workspace.subdomain.to_s.downcase)
    end

    def valid_signup?
      ok = @workspace.valid?
      if @email.blank? || !@email.include?("@")
        @workspace.errors.add(:base, "Email không hợp lệ"); ok = false
      end
      if params[:password].to_s.length < 6
        @workspace.errors.add(:base, "Mật khẩu tối thiểu 6 ký tự"); ok = false
      end
      ok
    end

    def preset_for(industry)
      { "fnb" => "cozy_cafe", "service" => "modern_beauty", "retail" => "retail_bold" }[industry] || "cozy_cafe"
    end
  end
end
