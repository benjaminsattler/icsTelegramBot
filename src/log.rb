def log(msg)
    Logger.log(msg)
end

class Logger
    def self.setLogfile(filename)
        $stdout.reopen(filename)
        $stderr = $stdout        
    end

    def self.log(msg)
        puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} (#{caller.first}): #{msg}"
        STDOUT.flush
    end
end

