class Api::V1::GameRulesController < Api::V1::BaseController
  before_action :set_game_rule, only: [:show, :update, :destroy, :activate, :deactivate]
  
  # GET /api/v1/game_rules
  def index
    result = GameRulesService.list_game_rules(
      pagination_params.merge(
        search: params[:search],
        player_count: params[:player_count]&.to_i
      )
    )
    
    render_service_result(result)
  end
  
  # GET /api/v1/game_rules/:id
  def show
    result = GameRulesService.get_game_rule(params[:id])
    render_service_result(result)
  end
  
  # POST /api/v1/game_rules
  def create
    result = GameRulesService.create_game_rule(game_rule_params)
    render_service_result(result, success_status: :created)
  end
  
  # PUT /api/v1/game_rules/:id
  def update
    result = GameRulesService.update_game_rule(params[:id], game_rule_params)
    render_service_result(result)
  end
  
  # DELETE /api/v1/game_rules/:id
  def destroy
    result = GameRulesService.delete_game_rule(params[:id])
    render_service_result(result)
  end
  
  # POST /api/v1/game_rules/:id/activate
  def activate
    if @game_rule.update(active: true)
      render_success(@game_rule, message: "Game rule activated successfully")
    else
      render_error(@game_rule.errors.full_messages)
    end
  end
  
  # POST /api/v1/game_rules/:id/deactivate
  def deactivate
    if @game_rule.update(active: false)
      render_success(@game_rule, message: "Game rule deactivated successfully")
    else
      render_error(@game_rule.errors.full_messages)
    end
  end
  
  # POST /api/v1/game_rules/seed_templates
  def seed_templates
    result = GameRulesService.create_default_game_templates
    render_service_result(result, success_status: :created)
  end
  
  private
  
  def set_game_rule
    @game_rule = GameRule.find(params[:id])
  end
  
  def game_rule_params
    params.require(:game_rule).permit(
      :name, 
      :description, 
      :deck_size, 
      :min_players, 
      :max_players, 
      :version, 
      :active,
      rules_data: {}
    ).tap do |permitted|
      permitted[:created_by] = current_user_id
    end
  end
end 