require 'watchdog'
require 'bot'
require 'data'
require 'ics'
require 'log'
require 'container'

require 'yaml'

class MainThread

    @watchdog = nil
    @isRunning = false
    @config = nil

    def initialize
        I18n.load_path = Dir[File.join(File.dirname(__FILE__), '..', 'lang', '*.yml')]
        I18n.backend.load_translations
        I18n.default_locale = :de
        I18n.locale = config['locale'] unless ENV['LOCALE'].nil?

        env = ENV['ICSBOT_ENV'].nil? ? 'testing' : ENV['ICSBOT_ENV']
        @isRunning = true
        
        if !['production', 'testing'].include?(env) then
            log("Unknown environment #{env}. Terminating...")
            exit
        end
        
        log("Running in #{env.upcase} environment")
        configFilename  = case env
            when 'production'
                'prod.yml'
            when 'testing'
                'test.yml'
            end
        self.loadConfig(File.join [File.dirname(__FILE__), '..', 'config', configFilename])
    end

    def loadConfig(configFile)
        @config = YAML.load_file(configFile)
    end

    def run
        data = DataStore.new(File.join(File.dirname(__FILE__), '..', @config['db_path']))
        calendars = data.getCalendars.map do |calendar_desc|
            events = ICS::Calendar.new
            events.loadEvents(ICS::FileParser::parseICS(File.join(File.dirname(__FILE__), '..', calendar_desc[:ics_path])))
            calendar_desc[:eventlist] = events
            calendar_desc
        end
        bot = Bot.new(@config['bot_token'], data, calendars, @config['admin_users'])
        
        Container::set(:bot, bot)
        Container::set(:calendars, calendars)
        Container::set(:dataStore, data)
        @watchdog = Watchdog.new
        eventThread = nil
        databaseThread = nil
        botThread = nil
        
        eventThreadBlock  = lambda do
            begin
                while(not Thread.current[:stop]) do
                    calendars.each do |calendar|
                        calendar[:eventlist].getEvents.each do |event|
                            #bot.notify(event)
                        end
                        sleep 1
                    end
                end
            rescue Exception => e
                puts e.inspect
                puts e.backtrace
            end
        end
        
        databaseThreadBlock = lambda do
            begin
                run = true
                while(run) do
                    seconds = @config['flush_interval']
                    while(seconds > 0 && run) do
                        sleep 1
                        seconds = seconds - 1
                        run = false if Thread.current[:stop]
                    end
                    log("Syncing database...")
                    data.flush
                    log("Syncing done...")
                end
            rescue Exception => e
                puts e.inspect
                puts e.backtrace
            end
        end
        
        botThreadBlock = lambda do
            begin
                bot.run
            rescue Exception => e
                puts e.inspect
                puts e.backtrace
            end
        end
        
        Signal.trap("TERM") do
            @isRunning = false
            log("Termination signal received")
            self.stop
        end
        
        Signal.trap('SIGINT') do 
            # cannot handle SIGINT, because the telegram gem is trapping
            # this signal. Instead, we can throw SIGTERM and can react on that
            Process.kill('TERM', Process.pid)
        end
        
        @watchdog.watch([{
            name: 'Bot',
            thr: botThreadBlock
        }, {
            name: 'Database',
            thr: databaseThreadBlock
        }, {
            name: 'Event',
            thr: eventThreadBlock
        }])

        @isRunning = true
        
        while(@isRunning) do
            sleep 1
        end
    end

    def stop
        @watchdog.stop
    end
end
