require "test_helper"

class InsalesBillingCheckJobTest < ActiveJob::TestCase
  setup do
    @user = User.create!(
      email_address: "test@example.com",
      password: "password",
      insales_id: "12345",
      shop: "test-shop.myinsales.ru",
      insales_charge_id: 999
    )
    
    Rails.application.credentials.stubs(:insales_app_identifier).returns("test_identifier")
    Rails.application.credentials.stubs(:insales_app_secret).returns("test_secret")
  end

  test "updates user billing information" do
    # Mock API response
    mock_response = {
      success: true,
      data: {
        "id" => 999,
        "status" => "active",
        "monthly" => "690.0",
        "trial_expired_at" => "2025-11-18",
        "paid_till" => "2025-12-11",
        "blocked" => false
      }
    }
    
    InsalesApiService.any_instance.stubs(:get_recurring_charge).returns(mock_response)
    
    InsalesBillingCheckJob.perform_now
    
    @user.reload
    assert_equal "active", @user.charge_status
    assert_equal 690.0, @user.monthly.to_f
    assert_equal Date.parse("2025-11-18"), @user.trial_ends_at
    assert_equal Date.parse("2025-12-11"), @user.paid_till
    assert_not @user.blocked
  end

  test "handles API errors gracefully" do
    mock_response = {
      success: false,
      error: "Not found"
    }
    
    InsalesApiService.any_instance.stubs(:get_recurring_charge).returns(mock_response)
    
    assert_nothing_raised do
      InsalesBillingCheckJob.perform_now
    end
  end
end

