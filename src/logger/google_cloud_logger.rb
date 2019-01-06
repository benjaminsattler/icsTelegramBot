# frozen_string_literal: true

require 'google/cloud/logging'

require 'logger/logger'

##
# This class sends logging output to google cloud engine
class GoogleCloudLogger < Logger
  def initialize(config)
    super(config)
    @logger = Google::Cloud::Logging.new(
      project: config.get('googleCloudLogger.project')
    )
  end

  def log(message, trace)
    entry = @logger.entry
    # The data to log
    entry.payload = message
    # The name of the log to write to
    entry.log_name = @config.get('googleCloudLogger.logname')
    # The resource associated with the data
    entry.resource.type = @config.get('googleCloudLogger.resource_type')

    caller_pattern = /^([^:]+):(\d+):in\s+`([^']+)'$/
    fn = trace.first
    caller_info = caller_pattern.match(fn)
    entry.source_location.file = caller_info[1]
    entry.source_location.line = caller_info[2].to_i
    entry.source_location.function = caller_info[3]

    entry.labels = {
      'environment' => @config.get('googleCloudLogger.environment')
    }

    # Writes the log entry
    @logger.write_entries entry
  end
end
