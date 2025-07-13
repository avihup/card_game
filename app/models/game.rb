class Game < ApplicationRecord
  field :name, type: String
  field :description, type: String
  field :max_players, type: Integer, default: 4
  field :min_players, type: Integer, default: 2
  field :active, type: Boolean, default: true
  
  validates :name, presence: true, uniqueness: true
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  def player_range
    "#{min_players}-#{max_players} players"
  end
end 