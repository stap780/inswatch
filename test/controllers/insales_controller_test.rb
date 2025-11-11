require "test_helper"

class InsalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @app_secret = "test_secret"
    @shop = "test-shop.myinsales.ru"
    @insales_id = "12345"
    
    # Stub credentials
    Rails.application.credentials.stubs(:insales_app_secret).returns(@app_secret)
    Rails.application.credentials.stubs(:insales_app_identifier).returns("test_identifier")
    Rails.application.credentials.stubs(:insales_billing_return_url).returns("https://example.com/insales/billing_callback")
  end

  def valid_signature_params(extra_params = {})
    params = {
      shop: @shop,
      insales_id: @insales_id
    }.merge(extra_params)
    
    # Generate signature
    filtered = params.except(:signature, :token, :controller, :action).with_indifferent_access
    base = filtered.sort_by { |k, _| k.to_s }.map { |k, v| "#{k}=#{v}" }.join
    signature = OpenSSL::HMAC.hexdigest("SHA256", @app_secret, base)
    
    params.merge(token: signature)
  end

  test "install with valid signature creates user" do
    params = valid_signature_params
    
    assert_difference "User.count", 1 do
      get insales_install_path, params: params
    end
    
    assert_response :success
    user = User.find_by(insales_id: @insales_id)
    assert_equal @shop, user.shop
    assert user.installed
  end

  test "install with invalid signature returns 401" do
    params = valid_signature_params.merge(token: "invalid")
    
    assert_no_difference "User.count" do
      get insales_install_path, params: params
    end
    
    assert_response :unauthorized
  end

  test "login with valid signature creates session" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password",
      insales_id: @insales_id,
      shop: @shop,
      installed: true
    )
    
    params = valid_signature_params
    
    get insales_login_path, params: params
    
    assert_redirected_to dashboard_path
    assert_equal user.id, Current.session&.user&.id
    assert_not_nil user.reload.last_login_at
  end

  test "login with invalid signature returns 401" do
    params = valid_signature_params.merge(token: "invalid")
    
    get insales_login_path, params: params
    
    assert_response :unauthorized
  end

  test "uninstall sets installed to false" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password",
      insales_id: @insales_id,
      shop: @shop,
      installed: true
    )
    
    post insales_uninstall_path, params: { shop: @shop, insales_id: @insales_id }
    
    assert_response :success
    assert_not user.reload.installed
  end

  test "billing_start requires authentication" do
    post insales_billing_start_path
    
    assert_redirected_to root_path
  end

  test "billing_callback with invalid signature returns 401" do
    params = valid_signature_params.merge(token: "invalid")
    
    get insales_billing_callback_path, params: params
    
    assert_response :unauthorized
  end
end

