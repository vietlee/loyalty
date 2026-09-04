module Customer
  class ProfileController < BaseController
    before_action :require_workspace!
    before_action :require_member!

    def show
      @member = current_member
    end

    def update
      @member = current_member
      attrs = profile_params
      raw_bday = params.dig(:member, :birthday).to_s.strip

      if raw_bday.present? && attrs[:birthday].nil?
        @member.assign_attributes(attrs.except(:birthday))
        @member.errors.add(:birthday, "không hợp lệ — nhập theo DD/MM/YYYY")
        return render :show, status: :unprocessable_entity
      end

      if @member.update(attrs)
        redirect_to member_profile_path, notice: t("customer.profile.updated")
      else
        render :show, status: :unprocessable_entity
      end
    end

    # Save just the avatar (separate from the name/email/birthday form).
    def avatar
      file = params.dig(:member, :avatar)
      if file.respond_to?(:original_filename) # a real uploaded file, not a string
        current_member.avatar.attach(file)
        redirect_to member_profile_path, notice: "Đã cập nhật ảnh đại diện."
      else
        redirect_to member_profile_path, alert: "Vui lòng chọn ảnh."
      end
    end

    private

    def profile_params
      p = params.require(:member).permit(:name, :email, :phone, :birthday, :avatar)
      p[:birthday] = parse_dmy(p[:birthday]) if p.key?(:birthday)
      p
    end

    # "01/03/1994" (or 1/3/1994, with - or .) → Date; nil if unparseable/blank.
    def parse_dmy(str)
      s = str.to_s.strip
      return nil if s.blank?
      d, m, y = s.split(%r{[/\-.]}).map { |x| x.to_i }
      Date.new(y, m, d)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
