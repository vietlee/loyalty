require "test_helper"

class RewardValidationsTest < ActiveSupport::TestCase
  setup { @ws = create(:workspace) }

  test "voucher/discount requires a value (no 500)" do
    with_tenant(@ws) do
      r = @ws.rewards.new(title: "X", kind: "discount", value_unit: "percent", value: nil)
      assert_not r.valid?
      assert r.errors[:value].any?
    end
  end

  test "percent value capped at 100" do
    with_tenant(@ws) do
      r = @ws.rewards.new(title: "X", kind: "discount", value_unit: "percent", value: 150)
      assert_not r.valid?
    end
  end

  test "gift defaults a blank value to 0" do
    with_tenant(@ws) do
      r = @ws.rewards.new(title: "Free cake", kind: "gift", value_unit: "item", value: nil, cost_points: 300)
      assert r.valid?, r.errors.full_messages.to_sentence
      assert_equal 0, r.value
    end
  end
end
