class GameSessionService
  class << self
    def create_game_session(game_rule_id, creator_user_id, creator_username)
      game_rule = GameRule.find(game_rule_id)
      
      game_session = GameSession.new(
        game_rule: game_rule,
        status: "waiting"
      )
      
      if game_session.save
        # Add creator as first player
        if game_session.add_player(creator_user_id, creator_username)
          ServiceResult.success(game_session)
        else
          ServiceResult.error(["Failed to add creator to game session"])
        end
      else
        ServiceResult.error(game_session.errors.full_messages)
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game rule not found"])
    end
    
    def join_game_session(session_id, user_id, username)
      game_session = GameSession.find(session_id)
      
      unless game_session.can_join?
        return ServiceResult.error(["Game session cannot be joined"])
      end
      
      if game_session.add_player(user_id, username)
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to join game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def leave_game_session(session_id, user_id)
      game_session = GameSession.find(session_id)
      
      if game_session.remove_player(user_id)
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to leave game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def start_game_session(session_id)
      game_session = GameSession.find(session_id)
      
      unless game_session.can_start?
        return ServiceResult.error(["Game session cannot be started"])
      end
      
      if game_session.start!
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to start game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def get_game_session(session_id, user_id = nil)
      game_session = GameSession.find(session_id)
      
      # Include user-specific data if user_id is provided
      session_data = serialize_game_session(game_session, user_id)
      
      ServiceResult.success(session_data)
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def play_turn(session_id, user_id, action_params)
      game_session = GameSession.find(session_id)
      
      unless game_session.status == "active"
        return ServiceResult.error(["Game session is not active"])
      end
      
      current_player = game_session.current_player
      unless current_player&.user_id == user_id
        return ServiceResult.error(["It's not your turn"])
      end
      
      # Process the action using GameEngineService
      result = GameEngineService.process_turn(game_session, user_id, action_params)
      
      if result.success?
        # Move to next player if turn completed successfully
        game_session.next_player!
        
        # Check for win condition
        winner = check_win_condition(game_session)
        if winner
          game_session.finish!(winner.user_id)
        end
        
        ServiceResult.success(serialize_game_session(game_session, user_id))
      else
        result
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def pause_game_session(session_id)
      game_session = GameSession.find(session_id)
      
      if game_session.pause!
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to pause game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def resume_game_session(session_id)
      game_session = GameSession.find(session_id)
      
      if game_session.resume!
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to resume game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def cancel_game_session(session_id)
      game_session = GameSession.find(session_id)
      
      if game_session.cancel!
        ServiceResult.success(game_session)
      else
        ServiceResult.error(["Failed to cancel game session"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      ServiceResult.error(["Game session not found"])
    end
    
    def list_game_sessions(params = {})
      page = params[:page] || 1
      per_page = params[:per_page] || 10
      
      sessions = GameSession.includes(:game_rule, :game_players)
      
      # Apply filters
      sessions = sessions.where(status: params[:status]) if params[:status]
      sessions = sessions.joinable if params[:joinable] == 'true'
      sessions = sessions.where(game_rule_id: params[:game_rule_id]) if params[:game_rule_id]
      
      paginated_sessions = sessions.page(page).per(per_page)
      
      ServiceResult.success({
        game_sessions: paginated_sessions.map { |session| serialize_game_session(session) },
        pagination: {
          current_page: page,
          per_page: per_page,
          total_pages: paginated_sessions.total_pages,
          total_count: paginated_sessions.total_count
        }
      })
    end
    
    private
    
    def serialize_game_session(game_session, user_id = nil)
      players = game_session.game_players.order_by(:position => :asc).map do |player|
        if user_id
          player.player_stats.merge(
            hand: player.serialize_hand_for_player(user_id)
          )
        else
          player.player_stats
        end
      end
      
      {
        id: game_session.id.to_s,
        game_rule: {
          id: game_session.game_rule.id.to_s,
          name: game_session.game_rule.name,
          description: game_session.game_rule.description,
          player_range: game_session.game_rule.player_range
        },
        status: game_session.status,
        current_player_index: game_session.current_player_index,
        turn_count: game_session.turn_count,
        players: players,
        player_count: game_session.player_count,
        can_join: game_session.can_join?,
        can_start: game_session.can_start?,
        is_full: game_session.is_full?,
        started_at: game_session.started_at,
        finished_at: game_session.finished_at,
        winner_id: game_session.winner_id,
        duration: game_session.duration,
        game_state: user_id ? game_session.game_state : game_session.game_state.except('deck')
      }
    end
    
    def check_win_condition(game_session)
      win_condition = game_session.game_rule.rules_data['win_condition']
      
      case win_condition
      when 'first_to_empty_hand'
        game_session.game_players.find { |player| player.hand.empty? }
      when 'highest_score'
        game_session.game_players.max_by(&:score)
      when 'lowest_score'
        game_session.game_players.min_by(&:score)
      when 'last_player_standing'
        active_players = game_session.game_players.active
        active_players.count == 1 ? active_players.first : nil
      else
        nil
      end
    end
  end
end 