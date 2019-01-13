# frozen_string_literal: true

require 'logger/logger'

##
# This logger logs straight to stdout
class StdoutLogger < Logger
  def initialize(config = {})
    super(config)
  end

  def log(message, trace)
    fn = trace.first
    puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} (#{fn}): #{message}"
  end
end
