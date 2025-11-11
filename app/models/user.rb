class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # InSales validations
  validates :insales_id, presence: true, uniqueness: true, if: -> { insales_id.present? }
  validates :shop, presence: true, if: -> { shop.present? }

  after_create_commit :create_insales_charge_after_install

  private

  def create_insales_charge_after_install
    return unless insales_id.present? && shop.present? && installed? && insales_api_password.present?
    begin
      client = InsalesApiClient.new(insales_api_password)
      response = client.create_recurring_charge(
        shop,
        price: 690.0,
        trial_days: 7
      )
      if response[:success]
        data = response[:data]
        update!(
          insales_charge_id: data["id"],
          charge_status: data["status"] || "pending",
          monthly: data["monthly"]&.to_d,
          trial_ends_at: data["trial_expired_at"]&.to_date,
          paid_till: data["paid_till"]&.to_date,
          blocked: data["blocked"] || false
        )
      else
        Rails.logger.error "Create charge after install failed for user #{id}: #{response[:error]}"
      end
    rescue => e
      Rails.logger.error "Create charge after install exception for user #{id}: #{e.message}"
    end
  end
end
