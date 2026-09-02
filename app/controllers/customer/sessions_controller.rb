module Customer
  class SessionsController < BaseController
    before_action :require_workspace!

    # Referral join link: stash the code, then go to login.
    def join
      session[:ref_code] = params[:code].to_s.upcase
      redirect_to member_login_path, notice: "Đăng nhập để nhận ưu đãi giới thiệu 🎁"
    end

    # Step 1 — enter email
    def new
      redirect_to(member_root_path) and return if member_signed_in? && current_member.workspace_id == current_workspace.id
      @email = ""
    end

    # Step 1 submit — issue OTP, go to verify screen
    def create
      @email = normalize(params[:email])
      unless @email&.match?(URI::MailTo::EMAIL_REGEXP)
        flash.now[:alert] = "Vui lòng nhập email hợp lệ."
        return render :new, status: :unprocessable_entity
      end
      OtpChallenge.issue!(workspace: current_workspace, email: @email)
      session[:otp_email] = @email
      redirect_to member_verify_path
    end

    # Step 2 — enter OTP
    def verify_form
      @email = session[:otp_email]
      redirect_to(member_login_path) and return if @email.blank?
      @dev_code = latest_dev_code(@email) if show_otp_onscreen?
    end

    # Step 2 submit — check OTP, sign in (create member on first login)
    def verify
      @email = session[:otp_email]
      redirect_to(member_login_path) and return if @email.blank?

      challenge = OtpChallenge.where(workspace: current_workspace, email: @email, purpose: "login")
                              .order(created_at: :desc).first
      result = challenge&.verify(params[:code])

      if result == :ok
        member = Member.find_by(workspace: current_workspace, email: @email)
        is_new = member.nil?
        if is_new && !current_workspace.can_add_member?
          flash.now[:alert] = "Chương trình đang tạm đầy. Vui lòng quay lại sau."
          return render :verify_form, status: :unprocessable_entity
        end
        member ||= Member.create!(workspace: current_workspace, email: @email)
        # Referral rewards apply ONLY to brand-new members.
        ref_code = session.delete(:ref_code)
        Referrals.attach(referred: member, referrer_code: ref_code) if is_new && ref_code.present?
        session.delete(:otp_email)
        member.remember_me = true          # keep them signed in for a long time
        sign_in(:member, member)
        redirect_to member_root_path, notice: "Chào mừng #{member.display_name}!"
      else
        @dev_code = latest_dev_code(@email) if show_otp_onscreen?
        flash.now[:alert] = otp_error_message(result)
        render :verify_form, status: :unprocessable_entity
      end
    end

    def destroy
      sign_out(:member)
      redirect_to member_login_path, notice: "Đã đăng xuất."
    end

    private

    def normalize(email)
      email.to_s.strip.downcase.presence
    end

    # Show the code on-screen in dev, when explicitly enabled, or until an email
    # delivery provider (SMTP) is configured.
    def show_otp_onscreen?
      ENV["SHOW_OTP"] == "true" || !Rails.env.production? || !EmailOtp.configured?
    end

    def latest_dev_code(email)
      OtpChallenge.where(workspace: current_workspace, email: email).order(created_at: :desc).first&.code
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
