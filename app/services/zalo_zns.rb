# Sends OTP via Zalo Notification Service (ZNS) template messages through a Zalo
# Official Account. OA access tokens expire (~1h) and refresh tokens rotate on
# each refresh, so both are stored durably in AppSetting.
#
# Required ENV (set once the OA + approved OTP template exist):
#   ZALO_APP_ID, ZALO_APP_SECRET, ZALO_ZNS_TEMPLATE_ID, ZALO_OA_REFRESH_TOKEN
#   (optional) ZALO_ZNS_OTP_PARAM  — the template's OTP parameter name (default "otp")
class ZaloZns
  SEND_URL  = "https://business.openapi.zalo.me/message/template".freeze
  TOKEN_URL = "https://oauth.zaloapp.com/v4/oa/access_token".freeze

  def self.configured?
    ENV["ZALO_APP_ID"].present? && ENV["ZALO_APP_SECRET"].present? &&
      ENV["ZALO_ZNS_TEMPLATE_ID"].present? &&
      (ENV["ZALO_OA_REFRESH_TOKEN"].present? || AppSetting.get("zns_refresh_token").present?)
  end

  # Returns true when ZNS accepted the message.
  def deliver(phone:, code:)
    token = access_token
    return false if token.blank?

    payload = { phone: normalize(phone), template_id: ENV["ZALO_ZNS_TEMPLATE_ID"],
                template_data: { ENV.fetch("ZALO_ZNS_OTP_PARAM", "otp") => code.to_s } }
    resp = Faraday.post(SEND_URL) do |req|
      req.headers["access_token"]  = token
      req.headers["Content-Type"]  = "application/json"
      req.body = JSON.generate(payload)
    end
    json = (JSON.parse(resp.body) rescue {})
    ok = json["error"].to_i.zero?
    Rails.logger.info("[ZNS] send phone=#{phone} error=#{json['error']} #{json['message']}")
    ok
  rescue => e
    Rails.logger.error("[ZNS] #{e.class}: #{e.message}")
    false
  end

  private

  # +84 format Zalo expects (0xxxxxxxxx -> 84xxxxxxxxx).
  def normalize(phone)
    d = phone.to_s.gsub(/\D/, "")
    d = "84#{d[1..]}" if d.start_with?("0")
    d = "84#{d}" unless d.start_with?("84")
    d
  end

  def access_token
    cur = AppSetting.get("zns_access_token")
    exp = AppSetting.get("zns_token_expiry").to_i
    return cur if cur.present? && Time.now.to_i < (exp - 120)
    refresh!
  end

  def refresh!
    rt = AppSetting.get("zns_refresh_token").presence || ENV["ZALO_OA_REFRESH_TOKEN"]
    return nil if rt.blank?

    resp = Faraday.post(TOKEN_URL) do |req|
      req.headers["secret_key"]   = ENV["ZALO_APP_SECRET"]
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(refresh_token: rt, app_id: ENV["ZALO_APP_ID"], grant_type: "refresh_token")
    end
    j = (JSON.parse(resp.body) rescue {})
    return nil if j["access_token"].blank?

    AppSetting.set("zns_access_token", j["access_token"])
    AppSetting.set("zns_refresh_token", j["refresh_token"]) if j["refresh_token"].present?
    AppSetting.set("zns_token_expiry", (Time.now.to_i + j["expires_in"].to_i).to_s)
    j["access_token"]
  rescue => e
    Rails.logger.error("[ZNS] token refresh #{e.class}: #{e.message}")
    nil
  end
end
