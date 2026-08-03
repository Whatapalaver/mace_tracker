class ExercisesController < ApplicationController
  def index
    @exercises = Exercise.includes(:equipment).order(:name)
  end

  def new
    @exercise = Exercise.new
    @equipment = Equipment.order(:name)
  end

  def create
    @exercise = Exercise.new(exercise_params)

    if @exercise.save
      redirect_to exercises_path, notice: "Exercise added."
    else
      @equipment = Equipment.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  private

  def exercise_params
    params.expect(exercise: [ :name, :arm, :equipment_id, :notes ])
  end
end
