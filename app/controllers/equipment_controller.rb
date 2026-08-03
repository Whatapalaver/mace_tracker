class EquipmentController < ApplicationController
  def index
    @equipment = Equipment.order(:name)
  end

  def new
    @equipment = Equipment.new
  end

  def create
    @equipment = Equipment.new(equipment_params)

    if @equipment.save
      redirect_to equipment_index_path, notice: "Equipment added."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def equipment_params
    params.expect(equipment: [ :name ])
  end
end
