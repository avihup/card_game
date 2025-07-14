class GameSession < ApplicationRecord
  field :game_rule_id, type: BSON::ObjectId
  field :status, type: String, default: "waiting"
  field :current_player_index, type: Integer, default: 0
  field :game_state, type: Hash, default: {}
  field :deck, type: Array, default: []
  field :turn_count, type: Integer, default: 0
  field :winner_id, type: String
  field :started_at, type: DateTime
  field :finished_at, type: DateTime
  field :max_players_reached, type: Boolean, default: false
  
  belongs_to :game_rule
  has_many :game_players, dependent: :destroy
  
  validates :status, inclusion: { in: %w[waiting active paused finished cancelled] }
  validates :current_player_index, numericality: { greater_than_or_equal_to: 0 }
  validates :turn_count, numericality: { greater_than_or_equal_to: 0 }
  
  validate :player_count_within_game_rule_limits
  
  scope :active, -> { where(status: "active") }
  scope :waiting, -> { where(status: "waiting") }
  scope :finished, -> { where(status: "finished") }
  scope :joinable, -> { where(status: "waiting") }
  
  def can_start?
    status == "waiting" && 
    game_players.count >= game_rule.min_players && 
    game_players.count <= game_rule.max_players
  end
  
  def can_join?
    status == "waiting" && game_players.count < game_rule.max_players
  end
  
  def is_full?
    game_players.count >= game_rule.max_players
  end
  
  def current_player
    return nil unless status == "active" && game_players.exists?
    game_players.find_by(position: current_player_index)
  end
  
  def next_player!
    return false unless status == "active"
    
    self.current_player_index = (current_player_index + 1) % game_players.count
    self.turn_count += 1
    save!
  end
  
  def start!
    return false unless can_start?
    
    transaction do
      initialize_game_state
      update!(
        status: "active",
        started_at: Time.current,
        current_player_index: 0,
        turn_count: 1
      )
    end
    true
  end
  
  def finish!(winner_id = nil)
    update!(
      status: "finished",
      finished_at: Time.current,
      winner_id: winner_id
    )
  end
  
  def pause!
    update!(status: "paused") if status == "active"
  end
  
  def resume!
    update!(status: "active") if status == "paused"
  end
  
  def cancel!
    update!(status: "cancelled")
  end
  
  def add_player(user_id, username)
    return false unless can_join?
    
    position = game_players.count
    game_players.create!(
      user_id: user_id,
      username: username,
      position: position,
      hand: [],
      score: 0,
      player_data: {}
    )
  end
  
  def remove_player(user_id)
    player = game_players.find_by(user_id: user_id)
    return false unless player
    
    player.destroy
    
    # Reorganize positions
    game_players.each_with_index do |p, index|
      p.update!(position: index)
    end
    
    # Cancel game if not enough players
    if game_players.count < game_rule.min_players
      cancel!
    end
    
    true
  end
  
  def player_count
    game_players.count
  end
  
  def duration
    return nil unless started_at
    
    end_time = finished_at || Time.current
    end_time - started_at
  end
  
  private
  
  def initialize_game_state
    # Initialize deck
    self.deck = generate_deck
    
    # Deal initial hands
    deal_initial_hands
    
    # Set initial game state
    self.game_state = {
      deck_remaining: deck.size,
      discard_pile: [],
      current_turn: 1,
      last_action: "game_started",
      special_conditions: {}
    }
  end
  
  def generate_deck
    DeckGeneratorService.generate_deck(game_rule.rules_data)
  end
  
  def deal_initial_hands
    initial_hand_size = game_rule.rules_data['initial_hand_size'] || 7
    
    game_players.each do |player|
      hand = deck.pop(initial_hand_size)
      player.update!(hand: hand)
    end
  end
  
  def player_count_within_game_rule_limits
    return unless game_rule
    
    count = game_players.count
    if count > game_rule.max_players
      errors.add(:base, "Too many players for this game")
    elsif status == "active" && count < game_rule.min_players
      errors.add(:base, "Not enough players for this game")
    end
  end
end 