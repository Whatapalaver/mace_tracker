class ToolsController < ApplicationController
  before_action :set_tool, only: [ :edit, :update, :destroy ]

  def index
    @tools = Tool.includes(:equipment).order(:name)
  end

  def new
    @tool = Tool.new
    @equipment = Equipment.order(:name)
  end

  def create
    @tool = Tool.new(tool_params)

    if @tool.save
      redirect_to tools_path, notice: "Tool added."
    else
      @equipment = Equipment.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @equipment = Equipment.order(:name)
  end

  def update
    if @tool.update(tool_params)
      redirect_to tools_path, notice: "Tool updated."
    else
      @equipment = Equipment.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tool.destroy
    redirect_to tools_path, notice: "Tool deleted."
  end

  private

  def set_tool
    @tool = Tool.find(params[:id])
  end

  def tool_params
    params.expect(tool: [ :name, :equipment_id, :notes ])
  end
end
