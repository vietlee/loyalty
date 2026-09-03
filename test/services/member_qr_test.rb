require "test_helper"

class MemberQrTest < ActiveSupport::TestCase
  setup do
    @ws = create(:workspace)
    @member = ActsAsTenant.with_tenant(@ws) { create(:member, workspace: @ws) }
  end

  test "encode/decode round trip" do
    tok = MemberQr.encode(@member)
    assert_equal @member.id, MemberQr.decode(tok, workspace: @ws)&.id
  end

  test "tampered token returns nil" do
    assert_nil MemberQr.decode("garbage--abc", workspace: @ws)
  end

  test "wrong workspace returns nil" do
    other = create(:workspace)
    tok = MemberQr.encode(@member)
    assert_nil MemberQr.decode(tok, workspace: other)
  end

  test "trailing whitespace is tolerated" do
    tok = MemberQr.encode(@member)
    assert_equal @member.id, MemberQr.decode(tok + "\n", workspace: @ws)&.id
  end
end
