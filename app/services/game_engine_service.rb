class GameEngineService
  class << self
    def process_turn(game_session, user_id, action_params)
      action = action_params[:action]
      player = game_session.game_players.find_by(user_id: user_id)
      
      return ServiceResult.error(["Player not found in game session"]) unless player
      
      case action
      when 'play_card'
        process_play_card(game_session, player, action_params)
      when 'draw_card'
        process_draw_card(game_session, player, action_params)
      when 'pass'
        process_pass(game_session, player, action_params)
      when 'discard'
        process_discard(game_session, player, action_params)
      when 'skip_turn'
        process_skip_turn(game_session, player, action_params)
      else
        ServiceResult.error(["Invalid action: #{action}"])
      end
    end
    
    def validate_move(game_session, player, action_params)
      action = action_params[:action]
      game_rule = game_session.game_rule
      
      # Check if action is allowed by game rules
      unless game_rule.rules_data['turn_actions'].include?(action)
        return ServiceResult.error(["Action '#{action}' not allowed in this game"])
      end
      
      # Validate specific action parameters
      case action
      when 'play_card'
        validate_play_card(game_session, player, action_params)
      when 'draw_card'
        validate_draw_card(game_session, player, action_params)
      when 'pass'
        validate_pass(game_session, player, action_params)
      when 'discard'
        validate_discard(game_session, player, action_params)
      else
        ServiceResult.success(true)
      end
    end
    
    def calculate_score(game_session, player)
      game_rule = game_session.game_rule
      scoring_rules = game_rule.rules_data['scoring']
      
      return 0 unless scoring_rules
      
      case scoring_rules['type']
      when 'points'
        calculate_points_score(player, scoring_rules)
      when 'sets'
        calculate_sets_score(player, scoring_rules)
      when 'elimination'
        player.hand.empty? ? 1 : 0
      else
        0
      end
    end
    
    def check_special_conditions(game_session, player, action_params)
      game_rule = game_session.game_rule
      special_rules = game_rule.rules_data['special_rules'] || {}
      
      results = []
      
      # Check for skip turn condition
      if special_rules['skip_turn'] && action_params[:action] == 'play_card'
        card = player.hand[action_params[:card_index]]
        if card && card['rank'] == 'skip'
          results << { type: 'skip_next_player', message: 'Next player skipped' }
        end
      end
      
      # Check for reverse direction
      if special_rules['reverse_direction'] && action_params[:action] == 'play_card'
        card = player.hand[action_params[:card_index]]
        if card && card['rank'] == 'reverse'
          results << { type: 'reverse_direction', message: 'Play direction reversed' }
        end
      end
      
      # Check for draw cards
      if special_rules['draw_two'] && action_params[:action] == 'play_card'
        card = player.hand[action_params[:card_index]]
        if card && card['rank'] == 'draw_two'
          results << { type: 'force_draw', count: 2, message: 'Next player draws 2 cards' }
        end
      end
      
      results
    end
    
    def update_game_state(game_session, action_type, action_data)
      game_state = game_session.game_state
      
      case action_type
      when 'card_played'
        game_state['discard_pile'] ||= []
        game_state['discard_pile'] << action_data[:card]
        game_state['last_action'] = "#{action_data[:player]} played #{action_data[:card]['rank']} of #{action_data[:card]['suit']}"
      when 'card_drawn'
        game_state['deck_remaining'] = game_session.deck.size
        game_state['last_action'] = "#{action_data[:player]} drew a card"
      when 'player_passed'
        game_state['last_action'] = "#{action_data[:player]} passed"
      when 'special_action'
        game_state['special_conditions'] ||= {}
        game_state['special_conditions'][action_data[:type]] = action_data[:data]
        game_state['last_action'] = action_data[:message]
      end
      
      game_session.update!(game_state: game_state)
    end
    
    private
    
    def process_play_card(game_session, player, action_params)
      card_index = action_params[:card_index]
      
      # Validate the move
      validation_result = validate_play_card(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Play the card
      card = player.play_card(card_index)
      return ServiceResult.error(["Invalid card index"]) unless card
      
      # Update game state
      update_game_state(game_session, 'card_played', {
        card: card,
        player: player.username
      })
      
      # Check for special conditions
      special_conditions = check_special_conditions(game_session, player, action_params)
      
      # Apply special conditions
      special_conditions.each do |condition|
        apply_special_condition(game_session, condition)
      end
      
      ServiceResult.success({
        action: 'card_played',
        card: card,
        player: player.username,
        special_conditions: special_conditions
      })
    end
    
    def process_draw_card(game_session, player, action_params)
      # Validate the move
      validation_result = validate_draw_card(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Draw a card from deck
      return ServiceResult.error(["No cards left in deck"]) if game_session.deck.empty?
      
      card = game_session.deck.pop
      player.draw_card(card)
      
      # Update game state
      update_game_state(game_session, 'card_drawn', {
        player: player.username
      })
      
      # Save the updated deck
      game_session.save!
      
      ServiceResult.success({
        action: 'card_drawn',
        player: player.username,
        cards_remaining: game_session.deck.size
      })
    end
    
    def process_pass(game_session, player, action_params)
      # Validate the move
      validation_result = validate_pass(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Update game state
      update_game_state(game_session, 'player_passed', {
        player: player.username
      })
      
      ServiceResult.success({
        action: 'passed',
        player: player.username
      })
    end
    
    def process_discard(game_session, player, action_params)
      card_index = action_params[:card_index]
      
      # Validate the move
      validation_result = validate_discard(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Discard the card
      card = player.play_card(card_index)
      return ServiceResult.error(["Invalid card index"]) unless card
      
      # Update game state
      update_game_state(game_session, 'card_played', {
        card: card,
        player: player.username
      })
      
      ServiceResult.success({
        action: 'card_discarded',
        card: card,
        player: player.username
      })
    end
    
    def process_skip_turn(game_session, player, action_params)
      # Update game state
      update_game_state(game_session, 'player_passed', {
        player: player.username
      })
      
      ServiceResult.success({
        action: 'turn_skipped',
        player: player.username
      })
    end
    
    def validate_play_card(game_session, player, action_params)
      card_index = action_params[:card_index]
      
      return ServiceResult.error(["Card index is required"]) unless card_index
      return ServiceResult.error(["Invalid card index"]) unless card_index >= 0 && card_index < player.hand.size
      
      card = player.hand[card_index]
      game_state = game_session.game_state
      
      # Check if card can be played (basic rule validation)
      if can_play_card?(card, game_state, game_session.game_rule)
        ServiceResult.success(true)
      else
        ServiceResult.error(["Card cannot be played"])
      end
    end
    
    def validate_draw_card(game_session, player, action_params)
      return ServiceResult.error(["No cards left in deck"]) if game_session.deck.empty?
      
      ServiceResult.success(true)
    end
    
    def validate_pass(game_session, player, action_params)
      # Check if pass is allowed by game rules
      game_rule = game_session.game_rule
      if game_rule.rules_data['turn_actions'].include?('pass')
        ServiceResult.success(true)
      else
        ServiceResult.error(["Pass action not allowed in this game"])
      end
    end
    
    def validate_discard(game_session, player, action_params)
      card_index = action_params[:card_index]
      
      return ServiceResult.error(["Card index is required"]) unless card_index
      return ServiceResult.error(["Invalid card index"]) unless card_index >= 0 && card_index < player.hand.size
      
      ServiceResult.success(true)
    end
    
    def can_play_card?(card, game_state, game_rule)
      # Basic card matching logic - can be extended based on specific game rules
      discard_pile = game_state['discard_pile'] || []
      
      # If no cards in discard pile, any card can be played
      return true if discard_pile.empty?
      
      last_card = discard_pile.last
      special_rules = game_rule.rules_data['special_rules'] || {}
      
      # Check for match suit or rank rule
      if special_rules['match_suit_or_rank']
        return card['suit'] == last_card['suit'] || card['rank'] == last_card['rank']
      end
      
      # Check for crazy eights rule
      if special_rules['crazy_eights']
        return card['rank'] == '8' || card['suit'] == last_card['suit'] || card['rank'] == last_card['rank']
      end
      
      # Default: any card can be played
      true
    end
    
    def apply_special_condition(game_session, condition)
      case condition[:type]
      when 'skip_next_player'
        game_session.next_player!
      when 'reverse_direction'
        # This would need more complex logic for direction reversal
        # For now, just log the condition
        Rails.logger.info("Direction reversed in game #{game_session.id}")
      when 'force_draw'
        next_player = game_session.game_players.find_by(position: (game_session.current_player_index + 1) % game_session.game_players.count)
        if next_player
          condition[:count].times do
            break if game_session.deck.empty?
            card = game_session.deck.pop
            next_player.draw_card(card)
          end
        end
      end
    end
    
    def calculate_points_score(player, scoring_rules)
      points = scoring_rules['points'] || {}
      total_score = 0
      
      player.hand.each do |card|
        card_points = points[card['rank']] || points['default'] || 0
        total_score += card_points
      end
      
      total_score
    end
    
    def calculate_sets_score(player, scoring_rules)
      # Count sets of cards with same rank
      rank_counts = player.hand.group_by { |card| card['rank'] }.transform_values(&:count)
      sets = rank_counts.values.count { |count| count >= 2 }
      
      sets * (scoring_rules['points']['set'] || 1)
    end
  end
end 