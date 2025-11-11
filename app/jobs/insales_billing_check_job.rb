class InsalesBillingCheckJob < ApplicationJob
  queue_as :default

  def perform
    users = User.where.not(insales_charge_id: nil)
    
    users.find_each do |user|
      next unless user.shop.present? && user.insales_charge_id.present?

      begin
        next unless user.insales_api_password.present?
        client = InsalesApiClient.new(user.insales_api_password)
        response = client.get_recurring_charge(user.shop, user.insales_charge_id)

        if response[:success]
          data = response[:data]
          user.update!(
            charge_status: data["status"],
            monthly: data["monthly"]&.to_d,
            trial_ends_at: data["trial_expired_at"]&.to_date,
            paid_till: data["paid_till"]&.to_date,
            blocked: data["blocked"] || false
          )
          Rails.logger.info "Updated billing for user #{user.id}: status=#{data['status']}, paid_till=#{data['paid_till']}"
        else
          Rails.logger.error "Failed to get charge for user #{user.id}: #{response[:error]}"
          
          # If rate limited, we'll retry later
          if response[:retry_after]
            Rails.logger.warn "Rate limited for user #{user.id}, will retry after #{response[:retry_after]} seconds"
            # Could enqueue a delayed job here if needed
          end
        end
      rescue => e
        Rails.logger.error "Error checking billing for user #{user.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end

