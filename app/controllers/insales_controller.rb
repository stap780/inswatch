class InsalesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:uninstall]
  allow_unauthenticated_access only: [:install, :login, :uninstall, :billing_callback]
  before_action :require_user, only: [:billing_start]

  # GET /insales/install
  def install
    shop = params[:shop].to_s
    insales_id = params[:insales_id].to_s
    token = params[:token].to_s

    # Compute shop API password per InSales spec: MD5(token + secret)
    api_password = Digest::MD5.hexdigest("#{token}#{Rails.application.credentials.insales_app_secret}")

    user = User.find_or_initialize_by(insales_id: insales_id)
    user.update!(shop: shop, installed: true, insales_api_password: api_password)

    head :ok
  end

  # GET /insales/login
  def login
    shop = params[:shop].to_s
    insales_id = params[:insales_id].to_s
    token = params[:token].to_s

    # Optional rotation: recompute password
    if token.present?
      api_password = Digest::MD5.hexdigest("#{token}#{Rails.application.credentials.insales_app_secret}")
      if (user = User.find_by(insales_id: insales_id, shop: shop))
        user.update!(insales_api_password: api_password)
      end
    end

    user = User.find_by!(insales_id: insales_id, shop: shop)
    user.update!(last_login_at: Time.current)

    # Use existing authentication system
    start_new_session_for(user)

    redirect_to dashboard_path
  end

  # GET/POST /insales/uninstall
  def uninstall
    if params[:shop].present? && params[:insales_id].present?
      user = User.find_by(insales_id: params[:insales_id].to_s, shop: params[:shop].to_s)
      user&.update!(installed: false)
    end

    head :ok
  end

  # POST /insales/billing_start
  def billing_start
    unless current_user.insales_id.present? && current_user.shop.present?
      redirect_to dashboard_path, alert: "InSales account not configured"
      return
    end

    return_url = Rails.application.credentials.insales_billing_return_url
    response = insales_api_client.create_recurring_charge(
      current_user.shop,
      price: 690.0,
      return_url: return_url,
      trial_days: 7
    )

    if response[:success]
      current_user.update!(
        insales_charge_id: response[:data]["id"],
        charge_status: response[:data]["status"] || "pending"
      )
      redirect_to response[:data]["confirmation_url"], allow_other_host: true
    else
      redirect_to dashboard_path, alert: "Failed to create charge: #{response[:error]}"
    end
  rescue => e
    Rails.logger.error "Billing start error: #{e.message}"
    redirect_to dashboard_path, alert: "Error creating subscription"
  end

  # GET /insales/billing_callback
  def billing_callback
    unless valid_signature?(request.query_parameters, Rails.application.credentials.insales_app_secret)
      return render plain: "Invalid signature", status: :unauthorized
    end

    charge_id = params[:charge_id] || params[:id]
    unless charge_id.present?
      redirect_to dashboard_path, alert: "Charge ID missing"
      return
    end

    user = User.find_by(insales_charge_id: charge_id)
    unless user
      redirect_to dashboard_path, alert: "User not found"
      return
    end

    # Get charge status from InSales
    response = insales_api_client.get_recurring_charge(user.shop, charge_id)

    if response[:success]
      data = response[:data]
      user.update!(
        charge_status: data["status"],
        monthly: data["monthly"]&.to_d,
        trial_ends_at: data["trial_expired_at"]&.to_date,
        paid_till: data["paid_till"]&.to_date,
        blocked: data["blocked"] || false
      )
      redirect_to dashboard_path, notice: "Subscription activated"
    else
      redirect_to dashboard_path, alert: "Failed to verify charge: #{response[:error]}"
    end
  rescue => e
    Rails.logger.error "Billing callback error: #{e.message}"
    redirect_to dashboard_path, alert: "Error processing subscription"
  end

  private

  def valid_signature?(params_hash, secret)
    filtered = params_hash.except(:signature, :token, :controller, :action).with_indifferent_access
    base = filtered.sort_by { |k, _| k.to_s }.map { |k, v| "#{k}=#{v}" }.join
    expected = OpenSSL::HMAC.hexdigest("SHA256", secret.to_s, base)
    provided = params_hash[:signature].presence || params_hash[:token].presence
    ActiveSupport::SecurityUtils.secure_compare(expected, provided.to_s.downcase)
  rescue
    false
  end

  def insales_api_client
    @insales_api_client ||= InsalesApiClient.new
  end
end

