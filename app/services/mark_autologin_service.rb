class MarkAutoLoginService
  SECRET = Rails.application.credentials.mark[:app_secret]

  # Генерирует подпись для запроса (MD5, как в InSales)
  def self.generate_signature(user_id, email, timestamp)
    message = "#{user_id}:#{email}:#{timestamp}"
    Digest::MD5.hexdigest(message + SECRET)
  end

  # Генерирует полный URL для автологина в Mark
  def self.mark_login_url(user, return_url: nil)
    timestamp = Time.now.to_i
    signature = generate_signature(user.id, user.email_address, timestamp)
    base_url = Rails.application.credentials.mark[:base_url]
    
    url = "#{base_url}/inswatch/autologin?" \
          "uid=#{user.id}" \
          "&email=#{CGI.escape(user.email_address)}" \
          "&timestamp=#{timestamp}" \
          "&signature=#{signature}"
    url += "&return_to=#{CGI.escape(return_url)}" if return_url.present?
    url += "&shop=#{CGI.escape(user.shop)}" if user.shop.present?
    url
  end

  # Устанавливает связь с Mark (вызывается автоматически после установки InSales)
  def self.install_mark_connection(user)
    return if user.mark_installed? # Уже установлено
    return unless user.email_address.present? # Нужен email для связи
    
    timestamp = Time.now.to_i
    signature = generate_signature(user.id, user.email_address, timestamp)
    base_url = Rails.application.credentials.mark[:base_url]
    
    install_url = "#{base_url}/inswatch/install?" \
                  "uid=#{user.id}" \
                  "&email=#{CGI.escape(user.email_address)}" \
                  "&timestamp=#{timestamp}" \
                  "&signature=#{signature}"
    install_url += "&shop=#{CGI.escape(user.shop)}" if user.shop.present?
    
    # Делаем запрос к Mark для установки (без редиректа пользователя)
    begin
      response = Net::HTTP.get_response(URI(install_url))
      
      if response.code == "200"
        # Обновляем флаг установки в Inswatch
        user.update_column(:mark_installed, true)
        Rails.logger.info "Mark connection installed for user #{user.id}"
      else
        Rails.logger.error "Failed to install Mark connection: #{response.code}"
      end
    rescue => e
      Rails.logger.error "Error installing Mark connection: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end

