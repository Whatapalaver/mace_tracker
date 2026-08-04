module SessionsExplorer
  extend ActiveSupport::Concern

  PER_PAGE = 50

  private

  # Populates every ivar the session history view needs. Pass locked_exercise (an Exercise) to
  # restrict to just that exercise with no equipment/exercise filter offered — the shared
  # dashboard uses this when a share link is scoped to a single exercise — otherwise
  # equipment_id/exercise_id come from params, exactly like the owner's own history page.
  def build_sessions_explorer(locked_exercise: nil)
    @exercise_locked = locked_exercise.present?

    # @years/@months only ever populate the filter dropdowns' options (so they only ever offer
    # choices with actual data) — the incoming params are validated separately and more loosely,
    # so that filtering down to a year/month with zero matching sessions still applies the filter
    # and shows an empty result, rather than being treated as "invalid" and silently ignored.
    @years = Session.distinct.pluck(:date).map(&:year).uniq.sort.reverse
    @year = params[:year].presence&.to_i

    @months = @year ? Session.where(date: Date.new(@year, 1, 1)..Date.new(@year, 12, 31))
                              .distinct.pluck(:date).map(&:month).uniq.sort : []
    @month = params[:month].presence&.to_i
    @month = nil unless @year && (1..12).cover?(@month)

    scope = Session.order(date: :desc, id: :desc)
    scope = scope.where(date: Date.new(@year, 1, 1)..Date.new(@year, 12, 31)) if @year
    scope = scope.where(date: Date.new(@year, @month, 1)..Date.new(@year, @month, -1)) if @year && @month

    if @exercise_locked
      @exercise_id = locked_exercise.id
      scope = scope.where(exercise_id: @exercise_id)
    else
      @equipment_list = Equipment.order(:name)
      @equipment_id = params[:equipment_id].presence
      @exercises = Exercise.order(:name)
      @exercises = @exercises.where(equipment_id: @equipment_id) if @equipment_id
      @exercise_id = params[:exercise_id].presence
      @exercise_id = nil if @exercise_id && !@exercises.exists?(id: @exercise_id)

      scope = scope.where(exercise_id: @exercise_id) if @exercise_id
      scope = scope.joins(:exercise).where(exercise: { equipment_id: @equipment_id }) if @equipment_id && !@exercise_id
    end

    @total_count = scope.count
    @total_pages = [ (@total_count / PER_PAGE.to_f).ceil, 1 ].max
    @page = [ [ params[:page].to_i, 1 ].max, @total_pages ].min
    @sessions = scope.includes(:exercise, :session_shape, :session_sets).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end
end
