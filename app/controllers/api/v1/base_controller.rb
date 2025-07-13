class Api::V1::BaseController < ApplicationController
  before_action :authenticate_user, except: [:health, :index]
  before_action :set_default_format
  
  rescue_from Mongoid::Errors::DocumentNotFound, with: :handle_not_found
  rescue_from Mongoid::Errors::Validations, with: :handle_validation_error
  rescue_from StandardError, with: :handle_internal_server_error
  
  private
  
  def set_default_format
    request.format = :json
  end
  
  def authenticate_user
    # Extract user from JWT token or use simple user_id parameter for now
    @current_user_id = params[:user_id] || request.headers['X-User-Id']
    @current_username = params[:username] || request.headers['X-Username'] || "User#{@current_user_id}"
    
    unless @current_user_id
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
  
  def current_user_id
    @current_user_id
  end
  
  def current_username
    @current_username
  end
  
  def render_success(data = nil, message: nil, status: :ok)
    response = { success: true }
    response[:data] = data if data
    response[:message] = message if message
    
    render json: response, status: status
  end
  
  def render_error(errors, message: nil, status: :unprocessable_entity)
    errors = [errors] unless errors.is_a?(Array)
    
    response = { 
      success: false, 
      errors: errors 
    }
    response[:message] = message if message
    
    render json: response, status: status
  end
  
  def render_service_result(result, success_status: :ok)
    if result.success?
      render_success(result.data, message: result.message, status: success_status)
    else
      render_error(result.errors, message: result.message)
    end
  end
  
  def handle_not_found(exception)
    render_error(["Resource not found"], status: :not_found)
  end
  
  def handle_validation_error(exception)
    render_error(exception.record.errors.full_messages, status: :unprocessable_entity)
  end
  
  def handle_internal_server_error(exception)
    Rails.logger.error "Internal Server Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render_error(
      ["Internal server error"], 
      message: Rails.env.development? ? exception.message : "An error occurred",
      status: :internal_server_error
    )
  end
  
  def pagination_params
    {
      page: params[:page] || 1,
      per_page: [params[:per_page]&.to_i || 10, 50].min
    }
  end
end 