class SharedDashboardsController < ApplicationController
  layout "shared"

  skip_before_action :authenticate_owner!
  before_action :set_share_link

  def show
    @period = params[:period].presence || "monthly"
    @stats = Progression::LifetimeStats.new(exercise: @share_link.exercise, period: @period)
    @sessions = @share_link.sessions.order(date: :desc).limit(50)
  end

  private

  def set_share_link
    @share_link = ShareLink.find_by(token: params[:token])
    head :not_found if @share_link.nil? || @share_link.expired?
  end
end
