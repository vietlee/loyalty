module Customer
  class SessionsController < BaseController
    before_action :require_workspace!

    # Referral join link: stash the code, then go to login.
    def join
      session[:ref_code] = params[:code].to_s.upcase
      redirect_to member_login_path, notice: "Đăng nhập để nhận ưu đãi giới thiệu 🎁"
    end

    # Step 1 — enter phone
    def new
      redirect_to(member_root_path) and return if member_signed_in? && current_member.workspace_id == current_workspace.id
      @phone = ""
    end

    # Step 1 submit — issue OTP, go to verify screen
    def create
      @phone = normalize(params[:phone])
      if @phone.blank?
        flash.now[:alert] = "Vui lòng nhập số điện thoại."
        return render :new, status: :unprocessable_entity
      end
      OtpChallenge.issue!(workspace: current_workspace, phone: @phone)
      session[:otp_phone] = @phone
      redirect_to member_verify_path
    end

    # Step 2 — enter OTP
    def verify_form
      @phone = session[:otp_phone]
      redirect_to(member_login_path) and return if @phone.blank?
      # Dev convenience: surface the latest code so testers can log in.
      @dev_code = latest_dev_code(@phone) unless Rails.env.production?
    end

    # Step 2 submit — check OTP, sign in (create member on first login)
    def verify
      @phone = session[:otp_phone]
      redirect_to(member_login_path) and return if @phone.blank?

      challenge = OtpChallenge.where(workspace: current_workspace, phone: @phone, purpose: "login")
                              .order(created_at: :desc).first
      result = challenge&.verify(params[:code])

      if result == :ok
        member = Member.find_or_create_by!(workspace: current_workspace, phone: @phone)
        if session[:ref_code].present?
          Referrals.attach(referred: member, referrer_code: session.delete(:ref_code))
        end
        session.delete(:otp_phone)
        sign_in(:member, member)
        redirect_to member_root_path, notice: "Chào mừng #{member.display_name}!"
      else
        @dev_code = latest_dev_code(@phone) unless Rails.env.production?
        flash.now[:alert] = otp_error_message(result)
        render :verify_form, status: :unprocessable_entity
      end
    end

    def destroy
      sign_out(:member)
      redirect_to member_login_path, notice: "Đã đăng xuất."
    end

    private

    def normalize(phone)
      phone.to_s.gsub(/\s+/, "").presence
    end

    def latest_dev_code(phone)
      OtpChallenge.where(workspace: current_workspace, phone: phone).order(created_at: :desc).first&.code
    end

    def otp_error_message(result)
      case result
      when :expired  then "Mã đã hết hạn. Vui lòng gửi lại."
      when :too_many then "Nhập sai quá nhiều lần. Vui lòng gửi lại mã."
      else "Mã xác thực không đúng."
      end
    end
  end
end
