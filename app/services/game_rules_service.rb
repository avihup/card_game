class GameRulesService
  class << self
    def create_game_rule(params)
      game_rule = GameRule.new(params)
      
      if game_rule.save
        ServiceResult.success(game_rule)
      else
        ServiceResult.error(game_rule.errors.full_messages)
      end
    end
    
    def update_game_rule(id, params)
      game_rule = GameRule.find(id)
      
      if game_rule.update(params)
        ServiceResult.success(game_rule)
      else
        ServiceResult.error(game_rule.errors.full_messages)
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game rule not found"])
    end
    
    def delete_game_rule(id)
      game_rule = GameRule.find(id)
      
      if game_rule.game_sessions.active.any?
        ServiceResult.error(["Cannot delete game rule with active sessions"])
      else
        game_rule.destroy
        ServiceResult.success(message: "Game rule deleted successfully")
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game rule not found"])
    end
    
    def get_game_rule(id)
      game_rule = GameRule.find(id)
      ServiceResult.success(game_rule)
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game rule not found"])
    end
    
    def list_game_rules(params = {})
      page = params[:page] || 1
      per_page = params[:per_page] || 10
      
      rules = GameRule.active
      rules = rules.by_player_count(params[:player_count]) if params[:player_count]
      rules = rules.where(name: /#{params[:search]}/i) if params[:search]
      
      paginated_rules = rules.page(page).per(per_page)
      
      ServiceResult.success({
        game_rules: paginated_rules.to_a,
        pagination: {
          current_page: page,
          per_page: per_page,
          total_pages: paginated_rules.total_pages,
          total_count: paginated_rules.total_count
        }
      })
    end
    
    def validate_rules_structure(rules_data)
      errors = []
      
      # Check required fields
      required_fields = %w[initial_hand_size win_condition turn_actions]
      required_fields.each do |field|
        errors << "Missing required field: #{field}" unless rules_data[field]
      end
      
      # Validate turn_actions
      if rules_data['turn_actions']
        unless rules_data['turn_actions'].is_a?(Array)
          errors << "turn_actions must be an array"
        end
        
        # Turn actions are now completely configurable by the user
      end
      
      # Validate win_condition
      if rules_data['win_condition']
        valid_conditions = %w[first_to_empty_hand highest_score lowest_score last_player_standing]
        unless valid_conditions.include?(rules_data['win_condition'])
          errors << "Invalid win_condition: #{rules_data['win_condition']}"
        end
      end
      
      # Validate scoring if present
      if rules_data['scoring']
        validate_scoring_rules(rules_data['scoring'], errors)
      end
      
      errors
    end
    
    def create_default_game_templates
      templates = [
        {
          name: "Standard Card Game",
          description: "Basic card game with standard 52-card deck",
          deck_size: 52,
          min_players: 2,
          max_players: 6,
          rules_data: {
            initial_hand_size: 7,
            win_condition: "first_to_empty_hand",
            turn_actions: ["play_card", "draw_card"],
            deck_configuration: {
              description: "Standard 52-card deck with suits",
              cards: [
                { suit: "hearts", rank: "A", value: 1, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "2", value: 2, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "3", value: 3, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "4", value: 4, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "5", value: 5, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "6", value: 6, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "7", value: 7, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "8", value: 8, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "9", value: 9, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "10", value: 10, color: "red", type: "number", count: 1 },
                { suit: "hearts", rank: "J", value: 10, color: "red", type: "face", count: 1 },
                { suit: "hearts", rank: "Q", value: 10, color: "red", type: "face", count: 1 },
                { suit: "hearts", rank: "K", value: 10, color: "red", type: "face", count: 1 },
                { suit: "diamonds", rank: "A", value: 1, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "2", value: 2, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "3", value: 3, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "4", value: 4, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "5", value: 5, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "6", value: 6, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "7", value: 7, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "8", value: 8, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "9", value: 9, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "10", value: 10, color: "red", type: "number", count: 1 },
                { suit: "diamonds", rank: "J", value: 10, color: "red", type: "face", count: 1 },
                { suit: "diamonds", rank: "Q", value: 10, color: "red", type: "face", count: 1 },
                { suit: "diamonds", rank: "K", value: 10, color: "red", type: "face", count: 1 },
                { suit: "clubs", rank: "A", value: 1, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "2", value: 2, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "3", value: 3, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "4", value: 4, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "5", value: 5, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "6", value: 6, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "7", value: 7, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "8", value: 8, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "9", value: 9, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "10", value: 10, color: "black", type: "number", count: 1 },
                { suit: "clubs", rank: "J", value: 10, color: "black", type: "face", count: 1 },
                { suit: "clubs", rank: "Q", value: 10, color: "black", type: "face", count: 1 },
                { suit: "clubs", rank: "K", value: 10, color: "black", type: "face", count: 1 },
                { suit: "spades", rank: "A", value: 1, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "2", value: 2, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "3", value: 3, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "4", value: 4, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "5", value: 5, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "6", value: 6, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "7", value: 7, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "8", value: 8, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "9", value: 9, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "10", value: 10, color: "black", type: "number", count: 1 },
                { suit: "spades", rank: "J", value: 10, color: "black", type: "face", count: 1 },
                { suit: "spades", rank: "Q", value: 10, color: "black", type: "face", count: 1 },
                { suit: "spades", rank: "K", value: 10, color: "black", type: "face", count: 1 }
              ]
            },
            card_play_rules: {
              play_rules: [
                { type: "match_any_properties", properties: ["suit", "rank"] }
              ]
            },
            scoring: {
              type: "elimination",
              points: {}
            }
          },
          created_by: "system"
        },
        {
          name: "TAKI",
          description: "Israeli card game with sequences and special actions - fully configurable",
          deck_size: 112,
          min_players: 2,
          max_players: 10,
          rules_data: {
            initial_hand_size: 8,
            win_condition: "first_to_empty_hand",
            turn_actions: ["play_card", "draw_card", "taki_sequence", "change_color", "break_plus_three"],
            deck_configuration: {
              description: "Taki deck with colored numbers and special action cards",
              cards: [
                # Red cards (numbers 1-9, 2 of each)
                { suit: "red", rank: "1", value: 1, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "2", value: 2, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "3", value: 3, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "4", value: 4, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "5", value: 5, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "6", value: 6, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "7", value: 7, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "8", value: 8, color: "red", type: "number", count: 4 },
                { suit: "red", rank: "9", value: 9, color: "red", type: "number", count: 4 },
                # Red action cards
                { suit: "red", rank: "stop", value: 25, color: "red", type: "action", count: 4 },
                { suit: "red", rank: "plus", value: 10, color: "red", type: "action", count: 4 },
                { suit: "red", rank: "change_direction", value: 25, color: "red", type: "action", count: 4 },
                { suit: "red", rank: "taki", value: 30, color: "red", type: "action", count: 4 },
                # Yellow cards (same structure)
                { suit: "yellow", rank: "1", value: 1, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "2", value: 2, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "3", value: 3, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "4", value: 4, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "5", value: 5, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "6", value: 6, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "7", value: 7, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "8", value: 8, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "9", value: 9, color: "yellow", type: "number", count: 4 },
                { suit: "yellow", rank: "stop", value: 25, color: "yellow", type: "action", count: 4 },
                { suit: "yellow", rank: "plus", value: 10, color: "yellow", type: "action", count: 4 },
                { suit: "yellow", rank: "change_direction", value: 25, color: "yellow", type: "action", count: 4 },
                { suit: "yellow", rank: "taki", value: 30, color: "yellow", type: "action", count: 4 },
                # Special cards
                { suit: "special", rank: "super_taki", value: 50, color: "black", type: "special", count: 4 },
                { suit: "special", rank: "king", value: 50, color: "black", type: "special", count: 4 },
                { suit: "special", rank: "plus_three", value: 30, color: "black", type: "special", count: 4 },
                { suit: "special", rank: "break_plus_three", value: 30, color: "black", type: "special", count: 4 },
                { suit: "wild", rank: "change_color", value: 30, color: "black", type: "wild", count: 8 }
              ]
            },
            card_play_rules: {
              play_rules: [
                { type: "match_any_properties", properties: ["color", "rank"] },
                { type: "always_playable", criteria: { type: "wild" } },
                { type: "always_playable", criteria: { type: "special" } }
              ],
              special_effects: [
                { criteria: { rank: "stop" }, type: "skip_player", message: "Next player skipped" },
                { criteria: { rank: "change_direction" }, type: "reverse_direction", message: "Direction reversed" },
                { criteria: { rank: "plus_three" }, type: "force_draw", data: { target: "all_other_players", count: 3 }, message: "All other players draw 3 cards" }
              ]
            },
            custom_actions: {
              "taki_sequence": {
                description: "Play multiple cards of the same color in sequence",
                requirements: [
                  { type: "has_card", criteria: { rank: "taki" } }
                ],
                state_changes: { "open_taki": true }
              },
              "break_plus_three": {
                description: "Break a +3 attack and redirect it",
                requirements: [
                  { type: "has_card", criteria: { rank: "break_plus_three" } }
                ]
              }
            },
            scoring: {
              type: "elimination",
              points: {}
            }
          },
          created_by: "system"
        }
      ]
      
      created_templates = []
      templates.each do |template|
        unless GameRule.where(name: template[:name]).exists?
          rule = GameRule.create!(template)
          created_templates << rule
        end
      end
      
      ServiceResult.success(created_templates)
    end
    
    private
    
    def validate_scoring_rules(scoring_data, errors)
      valid_scoring_types = %w[elimination points sets time_based]
      unless valid_scoring_types.include?(scoring_data['type'])
        errors << "Invalid scoring type: #{scoring_data['type']}"
      end
      
      if scoring_data['type'] == 'points' && !scoring_data['points']
        errors << "Points scoring requires points definition"
      end
    end
  end
end 