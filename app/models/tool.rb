class Tool < ApplicationRecord
  belongs_to :equipment
  # Nullified, not destroyed — deleting a tool (e.g. you no longer own that specific mace) should
  # never wipe the sessions logged with it, just clear which tool they were tagged with.
  has_many :sessions, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: [ :equipment_id, :user_id ] }

  def display_name
    "#{equipment.name}: #{name}"
  end

  # Grouped-select data for the log/edit-session "which tool did you use" picker — one optgroup
  # per equipment that actually has tools registered (equipment with none are left out, unlike
  # Equipment.filter_options, since an empty group here would just be dead weight in the picker).
  def self.grouped_options
    Equipment.includes(:tools).order(:name).filter_map do |equipment|
      next if equipment.tools.empty?

      [ equipment.name, equipment.tools.sort_by(&:name).map { |tool| [ tool.name, tool.id ] } ]
    end
  end

  # Parses the combined equipment/tool filter value used by the grouped equipment <select> on
  # the stats/history filter forms — either a bare equipment id ("3", meaning "this equipment,
  # any tool") or a "tool-<id>" value (meaning one specific tool, with its equipment implied) —
  # into the [equipment_id, tool] pair callers actually need to filter on.
  def self.resolve_filter_param(raw)
    return [ nil, nil ] if raw.blank?
    return [ raw, nil ] unless raw.start_with?("tool-")

    tool = find_by(id: raw.delete_prefix("tool-"))
    [ tool&.equipment_id&.to_s, tool ]
  end
end
