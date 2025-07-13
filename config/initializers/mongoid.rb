# Mongoid configuration
if defined?(Mongoid)
  Mongoid.load!(Rails.root.join("config", "mongoid.yml"))
  
  # Configure Mongoid to use Rails logger
  Mongoid.logger = Rails.logger
  
  # Set log level for Mongoid
  Mongoid.logger.level = Logger::INFO
  
  # Configure development-specific settings
  if Rails.env.development?
    # Enable query logging in development
    Mongoid.logger.level = Logger::DEBUG
  end
end 