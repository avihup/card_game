class ServiceResult
  attr_reader :success, :data, :errors, :message
  
  def initialize(success:, data: nil, errors: nil, message: nil)
    @success = success
    @data = data
    @errors = errors || []
    @message = message
  end
  
  def self.success(data = nil, message: nil)
    new(success: true, data: data, message: message)
  end
  
  def self.error(errors, message: nil)
    errors = [errors] unless errors.is_a?(Array)
    new(success: false, errors: errors, message: message)
  end
  
  def success?
    @success
  end
  
  def failure?
    !@success
  end
  
  def error?
    !@success
  end
  
  def first_error
    errors.first
  end
  
  def to_hash
    {
      success: success,
      data: data,
      errors: errors,
      message: message
    }.compact
  end
  
  def to_json(*args)
    to_hash.to_json(*args)
  end
end 