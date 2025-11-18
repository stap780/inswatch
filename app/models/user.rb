class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # InSales validations
  validates :insales_id, presence: true, uniqueness: true, if: -> { insales_id.present? }
  validates :shop, presence: true, if: -> { shop.present? }

  after_create_commit :create_insales_charge_after_install, if: -> { installed? }
  after_save_commit :add_connection_if_not_mark_installed, if: -> { installed? }

  def mark_installed?
    mark_installed == true
  end

  # Determine charge status based on blocked and paid_till
  def determine_charge_status(data = nil)
    data ||= {
      "blocked" => blocked,
      "paid_till" => paid_till&.to_s,
      "trial_expired_at" => trial_ends_at&.to_s
    }
    
    return "cancelled" if data["blocked"] == true
    
    if data["paid_till"].present?
      paid_date = Date.parse(data["paid_till"]) rescue nil
      if paid_date && Date.today <= paid_date
        return "active"
      elsif paid_date && Date.today > paid_date
        return "declined"
      end
    end
    
    if data["trial_expired_at"].present?
      trial_date = Date.parse(data["trial_expired_at"]) rescue nil
      if trial_date && Date.today <= trial_date
        return "pending"
      end
    end
    
    "pending"
  end

  private

  def create_insales_charge_after_install
    return unless insales_id.present? && shop.present? && installed? && insales_api_password.present?
    begin
      Rails.logger.info "Creating charge for user #{id}, shop: #{shop}, api_password present: #{insales_api_password.present?}"
      service = InsalesApiService.new(shop: shop, api_password: insales_api_password)
      response = service.create_recurring_charge(price: 799.0, trial_days: 10)
      if response[:success]
        data = response[:data]
        # InSales doesn't provide 'id' or 'status' in charge data
        # Determine status based on blocked and paid_till
        status = determine_charge_status(data)
        update!(
          monthly: data["monthly"]&.to_d,
          trial_ends_at: data["trial_expired_at"]&.to_date,
          paid_till: data["paid_till"]&.to_date,
          blocked: data["blocked"] || false,
          charge_status: status
        )
        Rails.logger.info "Charge created successfully for user #{id}"
      else
        Rails.logger.error "Create charge after install failed for user #{id}: #{response[:error]}"
      end
    rescue => e
      Rails.logger.error "Create charge after install exception for user #{id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def add_connection_if_not_mark_installed

    return if mark_installed? # Уже установлено
    return unless email_address.present? # Нужен email для связи
    
    MarkService.install_mark_connection(self)
  end
end
