# frozen_string_literal: true

def log(msg)
  Logger.log(msg)
end

##
# This class provides the means to output
# debugging messages in a well formatted manner.
class Logger
  def self.log(msg)
    puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} (#{caller.first}): #{msg}"
    $stdout.reopen(filename, 'a') if $stdout.closed?
  end
end
