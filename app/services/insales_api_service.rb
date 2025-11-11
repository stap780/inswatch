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
  def create_recurring_charge(price:, trial_days: 7, name: "Basic")
    configure
    
    charge = InsalesApi::RecurringApplicationCharge.new(
      name: name,
      price: price,
      trial_days: trial_days
    )
    
    if charge.save
      # Convert ActiveResource attributes to hash
      data = charge.attributes.dup
      # Convert string keys to match expected format
      data = data.transform_keys(&:to_s)
      { success: true, data: data }
    else
      { success: false, error: charge.errors.full_messages.join(", ") }
    end
  rescue ActiveResource::ResourceInvalid => e
    { success: false, error: "Invalid request: #{e.message}" }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  rescue ActiveResource::ForbiddenAccess
    { success: false, error: "Forbidden - check app permissions" }
  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end

  # Get recurring application charge by ID
  def get_recurring_charge(charge_id)
    configure
    
    charge = InsalesApi::RecurringApplicationCharge.find(charge_id)
    # Convert ActiveResource attributes to hash with string keys
    data = charge.attributes.dup.transform_keys(&:to_s)
    { success: true, data: data }
  rescue ActiveResource::ResourceNotFound
    { success: false, error: "Not found" }
  rescue ActiveResource::UnauthorizedAccess
    { success: false, error: "Unauthorized - check credentials" }
  rescue ActiveResource::ForbiddenAccess
    { success: false, error: "Forbidden - check app permissions" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end

  # Destroy recurring application charge
  def destroy_recurring_charge(charge_id)
    configure
    
    charge = InsalesApi::RecurringApplicationCharge.find(charge_id)
    if charge.destroy
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

  # Add free days to recurring application charge
  def add_free_days(charge_id, days)
    configure
    
    # Use ActiveResource post method for custom action
    response = InsalesApi::RecurringApplicationCharge.post(
      "#{charge_id}/add_free_days",
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

