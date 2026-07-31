class SessionSetsController < ApplicationController
  PER_PAGE = 25

  before_action :set_session_set, only: [ :show, :edit, :update, :destroy ]

  def index
    @page = [ params[:page].to_i, 1 ].max
    scope = SessionSet.joins(:session).includes(session: [ :exercise, :session_shape ])
                       .order(sessions: { date: :desc }, set_number: :asc)
    @total_count = scope.count
    @total_pages = [ (@total_count / PER_PAGE.to_f).ceil, 1 ].max
    @session_sets = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
  end

  def edit
  end

  def update
    ActiveRecord::Base.transaction do
      @session_set.session.update!(date: params[:date]) if params[:date].present?
      @session_set.update!(session_set_params)
    end

    render :show
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def destroy
    session = @session_set.session
    @session_set.destroy
    session.destroy if session.session_sets.none?

    redirect_to session_sets_path, notice: "Set deleted."
  end

  private

  def set_session_set
    @session_set = SessionSet.find(params[:id])
  end

  def session_set_params
    params.expect(session_set: [ :reps, :weight_kg, :duration_seconds, :rest_seconds_actual ])
  end
end
