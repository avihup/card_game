class GamePlayer < ApplicationRecord
  field :user_id, type: String
  field :username, type: String
  field :hand, type: Array, default: []
  field :score, type: Integer, default: 0
  field :position, type: Integer
  field :player_data, type: Hash, default: {}
  field :is_active, type: Boolean, default: true
  field :last_action_at, type: DateTime
  field :turn_order, type: Integer
  field :game_session_id, type: BSON::ObjectId
  
  belongs_to :game_session
  
  validates :user_id, presence: true
  validates :username, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :score, numericality: { greater_than_or_equal_to: 0 }
  
  validate :unique_user_per_game_session
  validate :unique_position_per_game_session
  
  scope :active, -> { where(is_active: true) }
  scope :by_position, -> { order(:position) }
  scope :by_turn_order, -> { order(:turn_order) }
  
  def hand_size
    hand.size
  end
  
  def has_cards?
    hand.any?
  end
  
  def is_current_player?
    game_session.current_player_index == position
  end
  
  def is_winner?
    game_session.winner_id == user_id
  end
  
  def play_card(card_index)
    return nil unless card_index >= 0 && card_index < hand.size
    
    card = hand.delete_at(card_index)
    update!(last_action_at: Time.current)
    card
  end
  
  def play_card_by_id(card_id)
    card_id = card_id.to_i
    card_index = hand.find_index { |card| card['id'] == card_id }
    return nil unless card_index
    
    card = hand.delete_at(card_index)
    update!(last_action_at: Time.current)
    card
  end
  
  def find_card_by_id(card_id)
    card_id = card_id.to_i
    hand.find { |card| card['id'] == card_id }
  end
  
  def has_card_id?(card_id)
    card_id = card_id.to_i
    hand.any? { |card| card['id'] == card_id }
  end
  
  def draw_card(card)
    hand << card
    update!(last_action_at: Time.current)
  end
  
  def add_score(points)
    self.score += points
    save!
  end
  
  def reset_score!
    update!(score: 0)
  end
  
  def deactivate!
    update!(is_active: false)
  end
  
  def activate!
    update!(is_active: true)
  end
  
  def has_card?(suit, rank)
    hand.any? { |card| card['suit'] == suit && card['rank'] == rank }
  end
  
  def cards_of_suit(suit)
    hand.select { |card| card['suit'] == suit }
  end
  
  def cards_of_rank(rank)
    hand.select { |card| card['rank'] == rank }
  end
  
  def highest_card
    return nil if hand.empty?
    
    hand.max_by { |card| card['value'] }
  end
  
  def lowest_card
    return nil if hand.empty?
    
    hand.min_by { |card| card['value'] }
  end
  
  def can_play_card?(card_index, game_state = {})
    return false unless card_index >= 0 && card_index < hand.size
    return false unless is_current_player?
    
    # Basic validation - can be extended based on game rules
    true
  end
  
  def can_play_card_by_id?(card_id, game_state = {})
    return false unless has_card_id?(card_id)
    return false unless is_current_player?
    
    # Basic validation - can be extended based on game rules
    true
  end
  
  def serialize_hand_for_player(requesting_user_id)
    if requesting_user_id == user_id
      # Return full hand for the player themselves
      hand
    else
      # Return only hand size for other players
      { hand_size: hand.size }
    end
  end
  
  def player_stats
    {
      user_id: user_id,
      username: username,
      score: score,
      hand_size: hand_size,
      position: position,
      is_active: is_active,
      is_current_player: is_current_player?,
      last_action_at: last_action_at
    }
  end
  
  private
  
  def unique_user_per_game_session
    return unless game_session && user_id
    
    existing_player = game_session.game_players.where(user_id: user_id).where(:id.ne => id).first
    if existing_player
      errors.add(:user_id, "is already in this game session")
    end
  end
  
  def unique_position_per_game_session
    return unless game_session && position
    
    existing_player = game_session.game_players.where(position: position).where(:id.ne => id).first
    if existing_player
      errors.add(:position, "is already taken in this game session")
    end
  end
end 