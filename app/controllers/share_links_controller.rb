class ShareLinksController < ApplicationController
  def index
    @share_links = ShareLink.order(created_at: :desc)
  end

  def new
    @share_link = ShareLink.new
    @exercises = Exercise.order(:name)
  end

  def create
    @share_link = ShareLink.new(expires_at: params.dig(:share_link, :expires_at), scope: scope_from_params)

    if @share_link.save
      redirect_to share_links_path, notice: "Share link created."
    else
      @exercises = Exercise.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    ShareLink.find(params[:id]).destroy
    redirect_to share_links_path, notice: "Share link revoked."
  end

  def regenerate
    ShareLink.find(params[:id]).regenerate_token
    redirect_to share_links_path, notice: "Share link regenerated - the old link no longer works."
  end

  private

  def scope_from_params
    exercise_id = params.dig(:share_link, :exercise_id)
    exercise_id.present? ? { "exercise_id" => exercise_id } : {}
  end
end
