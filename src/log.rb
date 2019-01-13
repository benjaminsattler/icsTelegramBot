# frozen_string_literal: true

require 'container'
require 'logger/google_cloud_logger'
require 'logger/stdout_logger'

def log(msg)
  logging = Container.get('logging')
  logging&.log(msg, caller(1))
end

##
# This class handles the actual logging and calls all
# configured loggers with a given log message
class Logging
  def initialize(config)
    @config = config
    @loggers = config.get('loggers').split(':').map do |logger_class|
      begin
        class_ref = Object.const_get(logger_class)
        if class_ref.nil?
          puts "Could not find logger class #{logger_class}. Skipping..."
        end
      rescue LoadError => e
        puts e.inspect
        puts "Could not load logger class #{logger_class}. Skipping..."
        class_ref = nil
      end
      class_ref
    end
    @loggers.reject(&:nil?)
    @loggers.map! { |logger| logger.new(config) }
  end

  def log(msg, trace)
    @loggers.each do |logger|
      logger.log(msg, trace)
    end
  end
end
