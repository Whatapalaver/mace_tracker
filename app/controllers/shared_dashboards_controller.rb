class SharedDashboardsController < ApplicationController
  include StatsExplorer
  include SessionsExplorer

  layout "shared"

  skip_before_action :authenticate_owner!
  before_action :set_share_link

  def show
    build_stats_explorer(locked_exercise: @share_link.exercise)
  end

  def sessions
    build_sessions_explorer(locked_exercise: @share_link.exercise)
  end

  private

  def set_share_link
    @share_link = ShareLink.find_by(token: params[:token])
    head :not_found if @share_link.nil? || @share_link.expired?
  end
end
