class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_owner!

  private

  # Single-user app — everything is gated behind one shared username/password except the
  # coach-facing share links (SharedDashboardsController skips this), which are meant to be
  # reachable by anyone with the unguessable token URL. Only enforced when credentials are
  # actually configured (via fly secrets in production), so local dev/test need no login.
  def authenticate_owner!
    configured_username = ENV["BASIC_AUTH_USER"]
    configured_password = ENV["BASIC_AUTH_PASSWORD"]
    return if configured_username.blank? || configured_password.blank?

    authenticate_or_request_with_http_basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, configured_username) &
        ActiveSupport::SecurityUtils.secure_compare(password, configured_password)
    end
  end
end
