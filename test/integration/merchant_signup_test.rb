require "test_helper"

class MerchantSignupTest < ActionDispatch::IntegrationTest
  setup do
    @victim = create(:user, email: "owner@shop.vn", password: "realpassword")
    @victim_ws = create(:workspace, name: "Victim Cafe", subdomain: "victimcafe")
    ActsAsTenant.with_tenant(@victim_ws) do
      @victim_ws.memberships.create!(user: @victim, role: "owner")
    end
  end

  def signup(email:, password:, subdomain:)
    post "/merchant/signup", params: {
      workspace: { name: "New Shop", subdomain: subdomain, industry: "fnb" },
      email: email, owner_name: "Someone", password: password
    }
  end

  test "signing up with an existing merchant's email and a wrong password is refused" do
    assert_no_difference -> { Workspace.count } do
      assert_no_difference -> { Membership.count } do
        signup(email: "owner@shop.vn", password: "guessing", subdomain: "attacker")
      end
    end
    assert_response :unprocessable_entity
    # And crucially: nobody got signed in as the victim.
    get "/merchant"
    assert_redirected_to "/merchant/login"
  end

  test "an existing owner proving their password may open a second shop" do
    assert_difference -> { Workspace.count }, 1 do
      signup(email: "owner@shop.vn", password: "realpassword", subdomain: "secondshop")
    end
    assert_equal 2, @victim.reload.workspaces.count
  end

  test "a brand-new email creates the account and signs it in" do
    assert_difference -> { User.count }, 1 do
      signup(email: "fresh@shop.vn", password: "secret123", subdomain: "freshshop")
    end
    assert_response :redirect
  end
end
