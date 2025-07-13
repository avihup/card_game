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
        
        valid_actions = %w[play_card draw_card pass discard skip_turn]
        invalid_actions = rules_data['turn_actions'] - valid_actions
        if invalid_actions.any?
          errors << "Invalid turn_actions: #{invalid_actions.join(', ')}"
        end
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
          name: "Classic UNO",
          description: "The classic UNO card game",
          deck_size: 108,
          min_players: 2,
          max_players: 10,
          rules_data: {
            initial_hand_size: 7,
            win_condition: "first_to_empty_hand",
            turn_actions: ["play_card", "draw_card"],
            special_rules: {
              skip_turn: true,
              reverse_direction: true,
              draw_two: true,
              wild_card: true
            },
            scoring: {
              type: "elimination",
              points: {}
            }
          },
          created_by: "system"
        },
        {
          name: "Go Fish",
          description: "Classic Go Fish card game",
          deck_size: 52,
          min_players: 2,
          max_players: 6,
          rules_data: {
            initial_hand_size: 7,
            win_condition: "most_sets",
            turn_actions: ["ask_for_card", "go_fish"],
            special_rules: {
              collect_sets: true,
              ask_specific_player: true
            },
            scoring: {
              type: "sets",
              points: { "set": 1 }
            }
          },
          created_by: "system"
        },
        {
          name: "Crazy Eights",
          description: "Classic Crazy Eights card game",
          deck_size: 52,
          min_players: 2,
          max_players: 7,
          rules_data: {
            initial_hand_size: 7,
            win_condition: "first_to_empty_hand",
            turn_actions: ["play_card", "draw_card"],
            special_rules: {
              crazy_eights: true,
              match_suit_or_rank: true
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