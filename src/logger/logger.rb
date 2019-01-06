# frozen_string_literal: true

##
# This interface define a Logger
class Logger
  def initialize(config)
    @config = config
  end

  def log(_message, _trace)
    raise NotImplementedError
  end
end
