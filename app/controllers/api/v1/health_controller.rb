class Api::V1::HealthController < Api::V1::BaseController
  def show
    begin
      # Check MongoDB connection
      GameRule.count
      
      render_success({
        status: 'healthy',
        version: Rails.application.config.version || '1.0.0',
        environment: Rails.env,
        timestamp: Time.current.iso8601,
        database: {
          status: 'connected',
          type: 'MongoDB'
        },
        services: {
          game_rules: GameRule.active.count,
          game_sessions: GameSession.active.count,
          waiting_games: GameSession.waiting.count
        }
      })
    rescue => e
      render_error(
        ["Database connection failed: #{e.message}"],
        status: :service_unavailable
      )
    end
  end
end 