class Equipment < ApplicationRecord
  has_many :exercises
  has_many :tools, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }

  # Grouped-select data for the combined equipment/tool filter used on the stats/history filter
  # forms — one optgroup per equipment, an "All <name>" option for the equipment itself plus one
  # option per tool registered under it (see Tool.resolve_filter_param for how the chosen value
  # is parsed back).
  def self.filter_options
    includes(:tools).order(:name).map do |equipment|
      tool_options = equipment.tools.sort_by(&:name).map { |tool| [ tool.name, "tool-#{tool.id}" ] }
      [ equipment.name, [ [ "All #{equipment.name}", equipment.id.to_s ] ] + tool_options ]
    end
  end
end
