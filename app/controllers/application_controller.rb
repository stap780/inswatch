class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private

  def current_user
    Current.user
  end

  def require_user
    unless current_user
      redirect_to root_path, alert: "Please sign in"
    end
  end

  def require_active_subscription
    return true if current_user.nil? # Skip if no user (will be caught by require_user)

    user = current_user
    active = user.charge_status == "active" &&
             !user.blocked &&
             (user.paid_till.nil? || Date.today <= user.paid_till)

    unless active
      redirect_to dashboard_path, alert: "Subscription required"
    end
  end
end
