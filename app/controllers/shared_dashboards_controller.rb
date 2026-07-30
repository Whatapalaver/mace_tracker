class SharedDashboardsController < ApplicationController
  layout "shared"

  before_action :set_share_link

  def show
    @stats = Progression::LifetimeStats.new(exercise: @share_link.exercise)
    @sessions = @share_link.sessions.order(date: :desc).limit(50)
  end

  private

  def set_share_link
    @share_link = ShareLink.find_by(token: params[:token])
    head :not_found if @share_link.nil? || @share_link.expired?
  end
end
