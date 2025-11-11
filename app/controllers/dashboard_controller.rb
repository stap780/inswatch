class DashboardController < ApplicationController
  before_action :require_user

  def index
    @user = current_user
  end
end

