def log(msg)
    Logger.log(msg)
end

class Logger
     def self.log(msg)
        puts "#{Time.now.strftime('%d.%m.%Y %H:%M:%S')} (#{caller[1]}): #{msg}"
        if $stdout.closed?
            $stdout.reopen(filename, 'a');
        end
    end
end
