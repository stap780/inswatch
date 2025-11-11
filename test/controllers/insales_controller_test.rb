require "test_helper"

class InsalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @app_secret = "test_secret"
    @shop = "test-shop.myinsales.ru"
    @insales_id = "12345"
    
    # Stub credentials
    Rails.application.credentials.stubs(:insales_app_secret).returns(@app_secret)
    Rails.application.credentials.stubs(:insales_app_identifier).returns("test_identifier")
  end

  def token_params(token: "token123", extra_params: {})
    {
      shop: @shop,
      insales_id: @insales_id,
      token: token
    }.merge(extra_params)
  end

  test "install computes and stores api password" do
    params = token_params
    expected_password = Digest::MD5.hexdigest("#{params[:token]}#{@app_secret}")

    assert_difference "User.count", 1 do
      get insales_install_path, params: params
    end

    assert_response :success
    user = User.find_by(insales_id: @insales_id)
    assert_equal @shop, user.shop
    assert user.installed
    assert_equal expected_password, user.insales_api_password
  end

  test "login sets session and updates api password" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password",
      insales_id: @insales_id,
      shop: @shop,
      installed: true
    )

    params = token_params(token: "rotated")
    rotated_password = Digest::MD5.hexdigest("#{params[:token]}#{@app_secret}")

    get insales_login_path, params: params

    assert_redirected_to dashboard_path
    assert_equal user.id, Current.session&.user&.id
    assert_not_nil user.reload.last_login_at
    assert_equal rotated_password, user.reload.insales_api_password
  end

  test "uninstall via GET sets installed to false" do
    user = User.create!(
      email_address: "test@example.com",
      password: "password",
      insales_id: @insales_id,
      shop: @shop,
      installed: true
    )

    get insales_uninstall_path, params: { shop: @shop, insales_id: @insales_id }

    assert_response :success
    assert_not user.reload.installed
  end

end

