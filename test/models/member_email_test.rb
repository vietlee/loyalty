require "test_helper"

class MemberEmailTest < ActiveSupport::TestCase
  test "gmail aliases collapse to one canonical address" do
    canon = "quocvietlee@gmail.com"
    assert_equal canon, Member.canonical_email("quocvietlee@gmail.com")
    assert_equal canon, Member.canonical_email("quocvietlee+1@gmail.com")
    assert_equal canon, Member.canonical_email("quoc.vietlee@gmail.com")
    assert_equal canon, Member.canonical_email("Quoc.Viet.Lee+shop@googlemail.com")
  end

  test "non-gmail keeps dots but strips +tag and lowercases" do
    assert_equal "user@outlook.com", Member.canonical_email("user+tag@outlook.com")
    assert_equal "a.b@company.com", Member.canonical_email("  A.B@Company.COM  ")
  end

  test "blank is nil" do
    assert_nil Member.canonical_email("")
    assert_nil Member.canonical_email(nil)
  end
end
