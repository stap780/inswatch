class InsalesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:uninstall]
  allow_unauthenticated_access only: [:install, :login, :uninstall]

  # GET /insales/install
  def install
    shop = params[:shop].to_s
    insales_id = params[:insales_id].to_s
    token = params[:token].to_s

    # Compute shop API password per InSales spec: MD5(token + secret_key)
    # Formula: password = MD5(token + secret_key)
    secret_key = Rails.application.credentials.insales_app_secret
    api_password = Digest::MD5.hexdigest(token + secret_key)

    user = User.find_or_initialize_by(insales_id: insales_id)
    if user.new_record?
      generated_email = "#{insales_id}@insales.local"
      generated_password = SecureRandom.base58(24)
      user.email_address = generated_email
      user.password = generated_password
      user.password_confirmation = generated_password
    end
    user.shop = shop
    user.installed = true
    user.insales_api_password = api_password
    user.save!

    head :ok
  end

  # GET /insales/login
  def login
    shop = params[:shop].to_s
    insales_id = params[:insales_id].to_s
    token = params[:token].to_s

    # Optional rotation: recompute password
    api_password = nil
    if token.present?
      secret_key = Rails.application.credentials.insales_app_secret
      api_password = Digest::MD5.hexdigest(token + secret_key)
    end

    # Find by insales_id first (since it's unique), then check/update shop
    user = User.find_by(insales_id: insales_id)
    
    if user.nil?
      # Create new user
      user = User.new(insales_id: insales_id, shop: shop)
      generated_email = "#{insales_id}@insales.local"
      generated_password = SecureRandom.base58(24)
      user.email_address = generated_email
      user.password = generated_password
      user.password_confirmation = generated_password
      user.installed = true
      user.insales_api_password = api_password if api_password.present?
      user.save!
    else
      # Update existing user's shop if different, and update password if provided
      user.update!(shop: shop) if user.shop != shop
      user.update!(insales_api_password: api_password) if api_password.present? && user.insales_api_password != api_password
    end
    
    user.update!(last_login_at: Time.current)

    # Use existing authentication system
    start_new_session_for(user)

    redirect_to dashboard_path
  end

  # GET/POST /insales/uninstall
  def uninstall
    if params[:shop].present? && params[:insales_id].present?
      user = User.find_by(insales_id: params[:insales_id].to_s, shop: params[:shop].to_s)
      user&.update!(installed: false, mark_installed: false)
    end

    head :ok
  end

  private

end

