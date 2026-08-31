module Merchant
  class DomainsController < BaseController
    before_action :require_manager!, except: [:show]

    def show
      @workspace = current_workspace
      @default_host = "#{@workspace.subdomain}.loyalty.vn"
      @verify_token = verify_token
    end

    def update
      domain = params.dig(:workspace, :custom_domain).to_s.downcase.strip.presence
      if current_workspace.update(custom_domain: domain, domain_verified_at: nil)
        redirect_to merchant_domain_path, notice: domain ? "Đã lưu tên miền. Vui lòng xác minh DNS." : "Đã gỡ tên miền riêng."
      else
        @default_host = "#{current_workspace.subdomain}.loyalty.vn"
        @verify_token = verify_token
        render :show, status: :unprocessable_entity
      end
    end

    # Dev stub: real deployment checks the DNS TXT record. Here we mark verified.
    def verify
      if current_workspace.custom_domain.present?
        current_workspace.update!(domain_verified_at: Time.current)
        redirect_to merchant_domain_path, notice: "Đã xác minh tên miền ✓ (giả lập DNS trong môi trường dev)."
      else
        redirect_to merchant_domain_path, alert: "Chưa có tên miền để xác minh."
      end
    end

    private

    def nav_key = :domain

    def verify_token
      "loyalty-verify=#{Digest::SHA256.hexdigest("#{current_workspace.id}-domain")[0, 24]}"
    end
  end
end
