require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates insales_id uniqueness when present" do
    user1 = User.create!(
      email_address: "test1@example.com",
      password: "password",
      insales_id: "12345",
      shop: "shop1.myinsales.ru"
    )
    
    user2 = User.new(
      email_address: "test2@example.com",
      password: "password",
      insales_id: "12345",
      shop: "shop2.myinsales.ru"
    )
    
    assert_not user2.valid?
    assert_includes user2.errors[:insales_id], "has already been taken"
  end

  test "allows multiple users without insales_id" do
    user1 = User.create!(
      email_address: "test1@example.com",
      password: "password"
    )
    
    user2 = User.new(
      email_address: "test2@example.com",
      password: "password"
    )
    
    assert user2.valid?
  end
end
