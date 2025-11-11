require "net/http"
require "json"
require "uri"

class InsalesApiClient
  BASE_URL = "https://api.insales.ru"

  def initialize(api_password = nil)
    @app_identifier = Rails.application.credentials.insales_app_identifier
    @api_password = api_password
  end

  # POST /admin/recurring_application_charges.json
  def create_recurring_charge(shop, price:, trial_days: 7, name: "Basic")
    url = URI("https://#{@app_identifier}:#{@api_password}@#{shop}/admin/recurring_application_charges.json")
    
    charge_params = {
      name: name,
      price: price
    }
    charge_params[:trial_days] = trial_days if trial_days.present?
    
    payload = {
      recurring_application_charge: charge_params
    }

    response = make_request(:post, url, payload)
    handle_response(response)
  end

  # GET /admin/recurring_application_charges/:id.json
  def get_recurring_charge(shop, charge_id)
    url = URI("https://#{@app_identifier}:#{@api_password}@#{shop}/admin/recurring_application_charges/#{charge_id}.json")
    response = make_request(:get, url)
    handle_response(response)
  end

  # DELETE /admin/recurring_application_charges/:id.json
  def destroy_recurring_charge(shop, charge_id)
    url = URI("https://#{@app_identifier}:#{@api_password}@#{shop}/admin/recurring_application_charges/#{charge_id}.json")
    response = make_request(:delete, url)
    handle_response(response)
  end

  # POST /admin/recurring_application_charges/:id/add_free_days.json
  def add_free_days(shop, charge_id, days)
    url = URI("https://#{@app_identifier}:#{@api_password}@#{shop}/admin/recurring_application_charges/#{charge_id}/add_free_days.json")
    payload = { days: days }
    response = make_request(:post, url, payload)
    handle_response(response)
  end

  private

  def make_request(method, uri, payload = nil)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 50

    # Extract userinfo from URI if present (format: https://user:pass@host)
    if uri.userinfo
      user, password = uri.userinfo.split(":", 2)
      uri.user = nil  # Clear userinfo from URI to avoid duplication
      uri.password = nil
    end

    request_class = case method
                    when :get
                      Net::HTTP::Get.new(uri.request_uri)
                    when :post
                      Net::HTTP::Post.new(uri.request_uri)
                    when :delete
                      Net::HTTP::Delete.new(uri.request_uri)
                    end

    request_class["Content-Type"] = "application/json"
    
    # Set Basic Auth if credentials were in URI
    if user && password
      request_class.basic_auth(user, password)
    end

    if payload && (method == :post || method == :put)
      request_class.body = payload.to_json
    end

    http.request(request_class)
  end

  def handle_response(response)
    case response.code.to_i
    when 200, 201
      { success: true, data: JSON.parse(response.body) }
    when 429
      retry_after = response["Retry-After"]&.to_i || 60
      { success: false, error: "Rate limit exceeded. Retry after #{retry_after} seconds", retry_after: retry_after }
    when 401
      { success: false, error: "Unauthorized - check credentials" }
    when 403
      { success: false, error: "Forbidden - check app permissions" }
    when 404
      { success: false, error: "Not found - endpoint or shop not found. Response: #{response.body[0..200]}" }
    when 400
      { success: false, error: "Bad request: #{response.body}" }
    when 500, 502, 503, 504
      { success: false, error: "Server error (#{response.code})" }
    else
      { success: false, error: "Unexpected response: #{response.code}" }
    end
  rescue JSON::ParserError => e
    { success: false, error: "Invalid JSON response: #{e.message}" }
  rescue => e
    { success: false, error: "Request failed: #{e.message}" }
  end
end

