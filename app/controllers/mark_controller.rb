class MarkController < ApplicationController
  before_action :require_authentication

  # GET /mark/login
  # Редирект на Mark с автологином
  def login
    return_url = params[:return_to] || params[:return_url]
    login_url = MarkService.mark_login_url(Current.user, return_url: return_url)
    
    redirect_to login_url, allow_other_host: true
  end
end

