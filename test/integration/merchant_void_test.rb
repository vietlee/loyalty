require "test_helper"

class MerchantVoidTest < ActionDispatch::IntegrationTest
  setup do
    @ws = create(:workspace, subdomain: "voidshop")
    @owner   = create(:user)
    @cashier = create(:user)
    ActsAsTenant.with_tenant(@ws) do
      @ws.memberships.create!(user: @owner, role: "owner")
      @ws.memberships.create!(user: @cashier, role: "cashier")
      @ws.update!(settings: @ws.settings.merge("onboarded" => true))
      create(:loyalty_program, workspace: @ws, earn_points: 1, earn_per_amount: 1000, tiers_enabled: false)
      @member = create(:member, workspace: @ws)
    end
  end

  def login(user)
    post "/merchant/logout"
    post "/merchant/login", params: { user: { email: user.email, password: "secret123" } }
  end

  def bill(staff:, at: nil)
    ActsAsTenant.with_tenant(@ws) do
      p = EarnPoints.new(member: @member, amount: 50_000, staff: staff).call.purchase
      p.update_columns(created_at: at) if at
      p
    end
  end

  test "an owner can undo a bill and the points come back off" do
    purchase = bill(staff: @cashier)
    login(@owner)
    post "/merchant/purchases/#{purchase.id}/void", params: { reason: "gõ nhầm" }
    assert_response :redirect
    assert purchase.reload.voided?
    assert_equal 0, ActsAsTenant.with_tenant(@ws) { @member.reload.points_balance }
  end

  test "a cashier cannot undo someone else's bill" do
    purchase = bill(staff: @owner)
    login(@cashier)
    post "/merchant/purchases/#{purchase.id}/void"
    assert_not purchase.reload.voided?
    assert_equal 50, ActsAsTenant.with_tenant(@ws) { @member.reload.points_balance }
  end

  test "a cashier cannot undo their own stale bill" do
    purchase = bill(staff: @cashier, at: 3.hours.ago)
    login(@cashier)
    post "/merchant/purchases/#{purchase.id}/void"
    assert_not purchase.reload.voided?
  end

  test "the scanner undo renders back inside the scan frame" do
    purchase = bill(staff: @cashier)
    login(@cashier)
    post "/merchant/purchases/#{purchase.id}/void", params: { frame: "scan_tool" }
    assert_response :success
    assert_match "scan_tool", response.body
    assert purchase.reload.voided?
  end

  test "a workspace with no activity still renders the dashboard" do
    login(@owner)
    get "/merchant"
    assert_response :success
    assert_match I18n.t("merchant.dashboard.retention_empty"), response.body
  end
end
