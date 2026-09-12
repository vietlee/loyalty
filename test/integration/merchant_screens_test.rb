require "test_helper"

# Smoke test: the screens touched by this change must actually render, in both
# locales (a missing translation key is a 500 in production).
class MerchantScreensTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create(:user)
    @ws = create(:workspace, subdomain: "smoke")
    ActsAsTenant.with_tenant(@ws) do
      @ws.memberships.create!(user: @owner, role: "owner")
      @ws.update!(settings: @ws.settings.merge("onboarded" => true))
      create(:loyalty_program, workspace: @ws)
      @ws.outlets.create!(code: "MAIN", name: "Chi nhánh chính", active: true)
      member = create(:member, workspace: @ws, name: "Khách A")
      EarnPoints.new(member: member, amount: 100_000, staff: @owner).call
      Rating.create!(workspace: @ws, member: member, stars: 2, comment: "Chờ lâu quá")
      MerchantAlerts.new_rating(Rating.last)
    end
    post "/merchant/login", params: { user: { email: @owner.email, password: "secret123" } }
  end

  %w[vi en].each do |locale|
    test "merchant screens render in #{locale}" do
      get "/set_locale/#{locale}"
      {
        "dashboard"    => "/merchant",
        "transactions" => "/merchant/transactions",
        "alerts"       => "/merchant/alerts",
        "feedback"     => "/merchant/feedback",
        "customers"    => "/merchant/customers"
      }.each do |name, path|
        get path
        assert_response :success, "#{name} (#{locale}) failed: #{response.status}"
        assert_no_match(/translation missing/i, response.body, "#{name} (#{locale}) has a missing translation")
      end
    end
  end

  test "the dashboard shows the retention numbers" do
    get "/merchant"
    assert_response :success
    assert_match I18n.t("merchant.dashboard.repeat_rate"), response.body
    assert_match I18n.t("merchant.dashboard.acquisition_title"), response.body
  end

  test "a manager can reply to a review and the customer is notified" do
    rating = ActsAsTenant.with_tenant(@ws) { Rating.first }
    assert_difference -> { Notification.count }, 1 do
      patch "/merchant/feedback/#{rating.id}/reply", params: { reply_body: "Quán xin lỗi bạn nhé!" }
    end
    assert_redirected_to "/merchant/feedback"
    assert_equal "Quán xin lỗi bạn nhé!", rating.reload.reply_body
    assert rating.replied?
  end

  test "the alert bell counts unread shop alerts" do
    get "/merchant"
    assert_match I18n.t("merchant.alerts.title"), response.body
    get "/merchant/alerts"
    assert_response :success
    assert_equal 0, ActsAsTenant.with_tenant(@ws) { MerchantAlert.unread.count }
  end
end
