class GameRule < ApplicationRecord
  field :name, type: String
  field :description, type: String
  field :deck_size, type: Integer, default: 52
  field :min_players, type: Integer
  field :max_players, type: Integer
  field :rules_data, type: Hash
  field :version, type: String, default: "1.0"
  field :created_by, type: String
  field :active, type: Boolean, default: true
  
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :deck_size, presence: true, numericality: { greater_than: 0 }
  validates :min_players, presence: true, numericality: { greater_than: 0 }
  validates :max_players, presence: true, numericality: { greater_than: 0 }
  validates :rules_data, presence: true
  validates :version, presence: true
  validates :created_by, presence: true
  
  validate :max_players_greater_than_min_players
  validate :rules_data_structure
  
  has_many :game_sessions, dependent: :destroy
  
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_player_count, ->(count) { where(:min_players.lte => count, :max_players.gte => count) }
  
  def player_range
    "#{min_players}-#{max_players} players"
  end
  
  def can_accommodate_players?(count)
    count >= min_players && count <= max_players
  end
  
  def deactivate!
    update!(active: false)
  end
  
  private
  
  def max_players_greater_than_min_players
    return unless min_players && max_players
    
    errors.add(:max_players, "must be greater than or equal to min_players") if max_players < min_players
  end
  
  def rules_data_structure
    return unless rules_data
    
    required_keys = %w[initial_hand_size win_condition turn_actions]
    required_keys.each do |key|
      errors.add(:rules_data, "must include #{key}") unless rules_data.key?(key)
    end
    
    if rules_data['turn_actions'] && !rules_data['turn_actions'].is_a?(Array)
      errors.add(:rules_data, "turn_actions must be an array")
    end
  end
end 