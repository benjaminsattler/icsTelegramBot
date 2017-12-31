require 'data'
require 'bot'
require 'ics'
require 'watchdog'
require 'log'

require 'i18n'
require 'fileutils'

class Server

    attr_reader :options
    def initialize(options)
        @options = options

        I18n.load_path = Dir[File.join(File.dirname(__FILE__), '..', 'lang', '*.yml')]
        I18n.backend.load_translations
        I18n.default_locale = :de
        I18n.locale = options['locale'] unless options['locale'].nil?
        #Logger.setLogfile(File.join(File.dirname(__FILE__), '..', options['log_file']))        
    end

    def pidfile?
        !@options['pid'].nil?
    end

    def pidfile
        @options['pid']
    end

    def logfile?
        !@options['log'].nil?
    end

    def logfile
        @options['log']
    end

    def daemon?
        !@options['daemon'].nil?
    end

    def daemon
        @options['daemon']
    end

    def daemonize
        puts "daemonizing"
        exit if fork
        Process.setsid
        exit if fork
    end
    
    def redirect_output(filename)
        FileUtils.mkdir_p(File.dirname(filename), :mode => 0755)
        FileUtils.touch filename
        File.chmod(0644, filename)
        $stderr.reopen(filename, 'a')
        $stdout.reopen($stderr)
        $stdout.sync = $stderr.sync = true
    end

    def status_from_pidfile
        return :dead unless self.pidfile?
        begin
            pid = File.read(self.pidfile).to_i
            return :dead if pid == 0
            return :running unless pid == 0
        rescue Errno::EPERM, Errno::EACCES
            return :running
        rescue Errno::ENOENT
            return :dead
        end
    end

    def write_pidfile
        begin
            FileUtils.mkdir_p(File.dirname(self.pidfile), :mode => 0755)
            FileUtils.touch self.pidfile
            pid = File.open(self.pidfile, 'w') { |f| f.write(Process.pid) }
            at_exit {
               puts "at exit"
               File.delete(self.pidfile) if File.exists?(self.pidfile)
            }
        rescue Errno::EPERM, Errno::EACCES
            puts "Cannot write PIDFILE #{self.pidfile}: Permission denied!"
            
        end
    end

    def check_running
        status = self.status_from_pidfile
        case status
        when :dead
            begin
                File.delete(self.pidfile)
            rescue Errno::EPERM, Errno::EACCES
                puts "Cannot delete PIDFILE #{self.pidfile}: Permission error!"
                exit
            rescue Errno::ENOENT
            end
        when :running
            puts "Server is already running! If you think this is a mistake, please delete pidfile #{File.expand_path(self.pidfile)}"
            exit
        end
    end

    def start
        
        self.check_running if self.pidfile?
        self.daemonize if self.daemon?
        self.write_pidfile if self.pidfile?
        self.redirect_output(self.logfile) if self.logfile?
        
        puts "logtest"
        while(true) do 
            sleep 1
        end
    end

    def run
        data = DataStore.new(File.join(File.dirname(__FILE__), '..', @options['db_path']))
        events = ICS::Calendar.new
        events.loadEvents(ICS::FileParser::parseICS(File.join(File.dirname(__FILE__), '..', @options['ics_path'])))
        bot = Bot.new(@options['bot_token'], data, events)
        
        watchdog = Watchdog.new
        eventThread = nil
        databaseThread = nil
        botThread = nil
        
        eventThreadBlock  = lambda do
            while(not Thread.current[:stop]) do
                events.getEvents.each do |event|
                    bot.notify(event)
                end
                sleep 1
            end
        end
        
        databaseThreadBlock = lambda do
            run = true
            while(run) do
                seconds = @options['flush_interval']
                while(seconds > 0 && run) do
                    sleep 1
                    seconds = seconds - 1
                    run = false if Thread.current[:stop]
                end
                log("Syncing database...")
                data.flush
                log("Syncing done...")
            end
        end
        
        botThreadBlock = lambda do
            bot.run
        end
        
        
        watchdog.watch([{
            name: 'Bot-Thread',
            thr: botThreadBlock
        }, {
            name: 'Database-Thread',
            thr: databaseThreadBlock
        }, {
            name: 'Event-Thread',
            thr: eventThreadBlock
        }])

        execute = true
        Signal.trap("TERM") do
            execute = false
            log("Shutdown signal received")
            watchdog.stop
        end

        while(execute) do
            sleep 1
        end
        
    end
    
end
