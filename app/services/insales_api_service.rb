# Service wrapper for InsalesApi gem
# Handles configuration and provides methods for RecurringApplicationCharge
class InsalesApiService
  def initialize(shop:, api_password:)
    @shop = shop
    @api_password = api_password
    @app_identifier = Rails.application.credentials.insales_app_identifier
  end

  # Configure InsalesApi for this shop
  def configure
    InsalesApi::App.api_key = @app_identifier
    InsalesApi::App.configure_api(@shop, @api_password)
  end

  # Create recurring application charge
  def create_recurring_charge(price:, trial_days: 10, name: "Basic")
    configure
        
    charge = InsalesApi::RecurringApplicationCharge.new(
      name: name,
      monthly: price,
      trial_days: trial_days
    )
    
    if charge.save
      # Convert ActiveResource attributes to hash
      data = charge.attributes.dup
      # Convert string keys to match expected format
      data = data.transform_keys(&:to_s)
      # Note: InSales doesn't return 'id' or 'status' in charge data
      # Available fields: monthly, trial_expired_at, created_at, updated_at, paid_till, blocked
      { success: true, data: data }
    else
      error_messages = charge.errors.full_messages.join(", ")
      Rails.logger.error "Charge validation failed: #{error_messages}"
      { success: false, error: error_messages }
    end
  rescue ActiveResource::ResourceInvalid => e
    error_msg = "Invalid request: #{e.message}"
    Rails.logger.error "ActiveResource::ResourceInvalid: #{error_msg}"
    Rails.logger.error e.backtrace.join("\n") if e.respond_to?(:backtrace)
    { success: false, error: error_msg }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  rescue ActiveResource::ForbiddenAccess
    { success: false, error: "Forbidden - check app permissions" }
  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end

  # Get current recurring application charge (InSales doesn't provide ID)
  def get_recurring_charge
    configure
    
    # InSales API doesn't provide ID for charge, so we get the current charge
    # Use find without parameters to get current charge
    begin
      charge = InsalesApi::RecurringApplicationCharge.find
      
      if charge && charge.respond_to?(:attributes)
        # Convert ActiveResource attributes to hash with string keys
        data = charge.attributes.dup.transform_keys(&:to_s)
        { success: true, data: data }
      else
        { success: false, error: "No charge found" }
      end
    rescue ActiveResource::ResourceNotFound
      { success: false, error: "Not found" }
    rescue ActiveResource::UnauthorizedAccess
      { success: false, error: "Unauthorized - check credentials" }
    rescue ActiveResource::ForbiddenAccess
      { success: false, error: "Forbidden - check app permissions" }
    rescue => e
      { success: false, error: "Request failed: #{e.message}" }
    end
  end

  # Destroy current recurring application charge
  def destroy_recurring_charge
    configure
    
    charge = get_recurring_charge
    return charge unless charge[:success]
    
    charge_obj = InsalesApi::RecurringApplicationCharge.new(charge[:data])
    if charge_obj.destroy
      { success: true, data: { status: "ok" } }
    else
      { success: false, error: "Failed to destroy charge" }
    end
  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end

  # Add free days to current recurring application charge
  def add_free_days(days)
    configure
    
    # Get current charge first
    charge_response = get_recurring_charge
    return charge_response unless charge_response[:success]
    
    # Use ActiveResource post method for custom action
    # Since we don't have ID, we'll need to use a different approach
    # Try posting to the charge endpoint directly
    response = InsalesApi::RecurringApplicationCharge.post(
      "add_free_days",
      { days: days }.to_json,
      { "Content-Type" => "application/json" }
    )
    
    { success: true, data: response }
  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end

  def get_account
    configure
    
    account = InsalesApi::Account.find
    
    if account
      # Convert ActiveResource attributes to hash
      data = account.attributes.dup
      # Convert string keys to match expected format
      data = data.transform_keys(&:to_s)
      { success: true, data: data }
    else
      { success: false, error: account.errors.full_messages.join(", ") }
    end

  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  end

end

