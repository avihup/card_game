class GameEngineService
  class << self
    def process_turn(game_session, user_id, action_params)
      action = action_params[:action]
      player = game_session.game_players.find_by(user_id: user_id)
      
      return ServiceResult.error(["Player not found in game session"]) unless player
      
      # Validate action is allowed
      unless game_session.game_rule.valid_turn_actions.include?(action)
        return ServiceResult.error(["Action '#{action}' not allowed in this game"])
      end
      
      case action
      when 'play_card'
        process_play_card(game_session, player, action_params)
      when 'draw_card'
        process_draw_card(game_session, player, action_params)
      when 'pass'
        process_pass(game_session, player, action_params)
      when 'discard'
        process_discard(game_session, player, action_params)
      else
        # Handle custom actions defined in rules
        process_custom_action(game_session, player, action, action_params)
      end
    end
    
    def validate_move(game_session, player, action_params)
      action = action_params[:action]
      game_rule = game_session.game_rule
      
      # Check if action is allowed by game rules
      unless game_rule.valid_turn_actions.include?(action)
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
        validate_custom_action(game_session, player, action, action_params)
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
        calculate_custom_score(player, scoring_rules)
      end
    end
    
    def check_special_conditions(game_session, player, action_params)
      game_rule = game_session.game_rule
      card_play_rules = game_rule.card_play_rules
      
      return [] unless card_play_rules['special_effects']
      
      results = []
      card = action_params[:action] == 'play_card' ? player.find_card_by_id(action_params[:card_id]) : nil
      
      card_play_rules['special_effects'].each do |effect|
        if matches_effect_criteria?(card, effect, game_session.game_state)
          results << {
            type: effect['type'],
            data: effect['data'] || {},
            message: effect['message'] || "Special effect triggered"
          }
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
        game_state['last_action'] = build_action_message(action_data[:player], 'played', action_data[:card])
      when 'card_drawn'
        game_state['deck_remaining'] = game_session.deck.size
        game_state['last_action'] = "#{action_data[:player]} drew a card"
      when 'player_passed'
        game_state['last_action'] = "#{action_data[:player]} passed"
      when 'special_action'
        game_state['special_conditions'] ||= {}
        game_state['special_conditions'][action_data[:type]] = action_data[:data]
        game_state['last_action'] = action_data[:message]
      when 'custom_action'
        game_state['last_action'] = action_data[:message] || "#{action_data[:player]} performed #{action_data[:action]}"
        game_state.merge!(action_data[:state_changes] || {})
      end
      
      game_session.update!(game_state: game_state)
    end

    private
    
    def process_play_card(game_session, player, action_params)
      card_id = action_params[:card_id]
      
      # Validate the move
      validation_result = validate_play_card(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Play the card
      card = player.play_card_by_id(card_id)
      return ServiceResult.error(["Invalid card ID or card not found"]) unless card
      
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
      card_id = action_params[:card_id]
      
      # Validate the move
      validation_result = validate_discard(game_session, player, action_params)
      return validation_result unless validation_result.success?
      
      # Discard the card
      card = player.play_card_by_id(card_id)
      return ServiceResult.error(["Invalid card ID or card not found"]) unless card
      
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
    
    def process_custom_action(game_session, player, action, action_params)
      custom_actions = game_session.game_rule.rules_data['custom_actions'] || {}
      action_config = custom_actions[action]
      
      return ServiceResult.error(["Unknown custom action: #{action}"]) unless action_config
      
      # Execute custom action logic
      result_data = {
        action: action,
        player: player.username
      }
      
      # Apply custom state changes
      if action_config['state_changes']
        update_game_state(game_session, 'custom_action', {
          player: player.username,
          action: action,
          state_changes: action_config['state_changes'],
          message: action_config['message']
        })
      end
      
      ServiceResult.success(result_data)
    end
    
    def validate_play_card(game_session, player, action_params)
      card_id = action_params[:card_id]
      
      return ServiceResult.error(["Card ID is required"]) unless card_id
      
      card = player.find_card_by_id(card_id)
      return ServiceResult.error(["Card not found in player's hand"]) unless card
      
      # Check if card can be played using configured rules
      if can_play_card?(card, game_session.game_state, game_session.game_rule)
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
      ServiceResult.success(true)
    end
    
    def validate_discard(game_session, player, action_params)
      card_id = action_params[:card_id]
      
      return ServiceResult.error(["Card ID is required"]) unless card_id
      return ServiceResult.error(["Card not found in player's hand"]) unless player.has_card_id?(card_id)
      
      ServiceResult.success(true)
    end
    
    def validate_custom_action(game_session, player, action, action_params)
      custom_actions = game_session.game_rule.rules_data['custom_actions'] || {}
      action_config = custom_actions[action]
      
      return ServiceResult.error(["Unknown custom action: #{action}"]) unless action_config
      
      # Validate custom action requirements
      if action_config['requirements']
        action_config['requirements'].each do |requirement|
          unless meets_requirement?(player, game_session, requirement)
            return ServiceResult.error(["Requirement not met: #{requirement['description']}"])
          end
        end
      end
      
      ServiceResult.success(true)
    end
    
    def can_play_card?(card, game_state, game_rule)
      card_play_rules = game_rule.card_play_rules
      discard_pile = game_state['discard_pile'] || []
      
      # If no cards in discard pile, check if first card rules exist
      if discard_pile.empty?
        first_card_rules = card_play_rules['first_card_rules']
        return first_card_rules ? meets_card_criteria?(card, first_card_rules) : true
      end
      
      last_card = discard_pile.last
      play_rules = card_play_rules['play_rules'] || []
      
      # Check each play rule to see if card can be played
      play_rules.any? do |rule|
        case rule['type']
        when 'match_property'
          card[rule['property']] == last_card[rule['property']]
        when 'match_any_properties'
          rule['properties'].any? { |prop| card[prop] == last_card[prop] }
        when 'match_all_properties'
          rule['properties'].all? { |prop| card[prop] == last_card[prop] }
        when 'always_playable'
          meets_card_criteria?(card, rule['criteria'] || {})
        when 'conditional'
          meets_condition?(rule['condition'], card, last_card, game_state)
        else
          false
        end
      end
    end
    
    def meets_card_criteria?(card, criteria)
      criteria.all? do |property, expected_value|
        case expected_value
        when Array
          expected_value.include?(card[property])
        else
          card[property] == expected_value
        end
      end
    end
    
    def meets_condition?(condition, card, last_card, game_state)
      # Implement conditional logic based on game state
      # This can be extended for complex conditional rules
      case condition['type']
      when 'state_property'
        game_state[condition['property']] == condition['value']
      when 'card_count'
        condition['operator'] == 'less_than' ? 
          card['count'] < condition['value'] : 
          card['count'] == condition['value']
      else
        true
      end
    end
    
    def matches_effect_criteria?(card, effect, game_state)
      return false unless card
      
      criteria = effect['criteria'] || {}
      criteria.all? do |property, expected_value|
        case expected_value
        when Array
          expected_value.include?(card[property])
        else
          card[property] == expected_value
        end
      end
    end
    
    def apply_special_condition(game_session, condition)
      case condition[:type]
      when 'skip_player'
        game_session.next_player!
      when 'reverse_direction'
        game_state = game_session.game_state
        game_state['direction'] = game_state['direction'] == 'clockwise' ? 'counterclockwise' : 'clockwise'
        game_session.update!(game_state: game_state)
      when 'force_draw'
        target_players = determine_target_players(game_session, condition[:data])
        target_players.each do |target_player|
          draw_count = condition[:data]['count'] || 1
          draw_count.times do
            break if game_session.deck.empty?
            card = game_session.deck.pop
            target_player.draw_card(card)
          end
        end
      when 'custom_effect'
        apply_custom_effect(game_session, condition[:data])
      end
    end
    
    def determine_target_players(game_session, effect_data)
      case effect_data['target']
      when 'next_player'
        [game_session.game_players.find_by(position: (game_session.current_player_index + 1) % game_session.game_players.count)]
      when 'all_other_players'
        game_session.game_players.where(:position.ne => game_session.current_player_index)
      when 'all_players'
        game_session.game_players.to_a
      else
        []
      end.compact
    end
    
    def apply_custom_effect(game_session, effect_data)
      # Apply custom effects defined in the game rules
      game_state = game_session.game_state
      
      if effect_data['state_changes']
        game_state.merge!(effect_data['state_changes'])
        game_session.update!(game_state: game_state)
      end
    end
    
    def build_action_message(player, action, card)
      "#{player} #{action} #{card['display_name'] || "#{card['rank']} of #{card['suit']}"}"
    end
    
    def calculate_points_score(player, scoring_rules)
      points = scoring_rules['points'] || {}
      total_score = 0
      
      player.hand.each do |card|
        card_points = points[card['rank']] || points[card['type']] || points['default'] || 0
        total_score += card_points
      end
      
      total_score
    end
    
    def calculate_sets_score(player, scoring_rules)
      # Implementation for set-based scoring
      0 # Placeholder
    end
    
    def calculate_custom_score(player, scoring_rules)
      # Implementation for custom scoring rules
      scoring_rules['default_score'] || 0
    end
    
    def meets_requirement?(player, game_session, requirement)
      case requirement['type']
      when 'has_card'
        player.hand.any? { |card| meets_card_criteria?(card, requirement['criteria']) }
      when 'hand_size'
        player.hand.size >= requirement['minimum']
      when 'game_state'
        game_session.game_state[requirement['property']] == requirement['value']
      else
        true
      end
    end
  end
end 