require "test_helper"

class CheckinServiceTest < ActiveSupport::TestCase
  setup { @ws = create(:workspace) }

  test "valid for the current nonce" do
    with_tenant(@ws) do
      ok, _ = Checkin.decode(Checkin.encode(@ws), workspace: @ws)
      assert ok
    end
  end

  test "rotating the nonce invalidates old codes" do
    with_tenant(@ws) do
      tok = Checkin.encode(@ws)
      @ws.rotate_checkin_nonce!
      ok, _ = Checkin.decode(tok, workspace: @ws)
      assert_not ok
    end
  end
end
