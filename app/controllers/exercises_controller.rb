class ExercisesController < ApplicationController
  before_action :set_exercise, only: [ :edit, :update, :destroy ]

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

  def edit
    @equipment = Equipment.order(:name)
  end

  def update
    if @exercise.update(exercise_params)
      redirect_to exercises_path, notice: "Exercise updated."
    else
      @equipment = Equipment.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @exercise.destroy
    redirect_to exercises_path, notice: "Exercise deleted."
  end

  private

  def set_exercise
    @exercise = Exercise.find(params[:id])
  end

  def exercise_params
    params.expect(exercise: [ :name, :arm, :equipment_id, :notes ])
  end
end
