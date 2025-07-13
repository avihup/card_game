class Api::V1::GameSessionsController < Api::V1::BaseController
  before_action :set_game_session, only: [:show, :join, :start, :play_turn, :leave, :pause, :resume, :cancel]
  
  # GET /api/v1/game_sessions
  def index
    result = GameSessionService.list_game_sessions(
      pagination_params.merge(
        status: params[:status],
        joinable: params[:joinable],
        game_rule_id: params[:game_rule_id]
      )
    )
    
    render_service_result(result)
  end
  
  # GET /api/v1/game_sessions/:id
  def show
    result = GameSessionService.get_game_session(params[:id], current_user_id)
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions
  def create
    result = GameSessionService.create_game_session(
      game_session_params[:game_rule_id], 
      current_user_id, 
      current_username
    )
    render_service_result(result, success_status: :created)
  end
  
  # POST /api/v1/game_sessions/:id/join
  def join
    result = GameSessionService.join_game_session(
      params[:id], 
      current_user_id, 
      current_username
    )
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions/:id/start
  def start
    result = GameSessionService.start_game_session(params[:id])
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions/:id/play_turn
  def play_turn
    result = GameSessionService.play_turn(
      params[:id], 
      current_user_id, 
      play_turn_params
    )
    render_service_result(result)
  end
  
  # DELETE /api/v1/game_sessions/:id/leave
  def leave
    result = GameSessionService.leave_game_session(params[:id], current_user_id)
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions/:id/pause
  def pause
    result = GameSessionService.pause_game_session(params[:id])
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions/:id/resume
  def resume
    result = GameSessionService.resume_game_session(params[:id])
    render_service_result(result)
  end
  
  # POST /api/v1/game_sessions/:id/cancel
  def cancel
    result = GameSessionService.cancel_game_session(params[:id])
    render_service_result(result)
  end
  
  private
  
  def set_game_session
    @game_session = GameSession.find(params[:id])
  end
  
  def game_session_params
    params.require(:game_session).permit(:game_rule_id)
  end
  
  def play_turn_params
    params.require(:play_turn).permit(:action, :card_index, :target_player_id, :target_suit, :target_rank)
  end
end 