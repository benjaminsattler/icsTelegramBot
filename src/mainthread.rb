require 'watchdog'
require 'bot'
require 'data'
require 'ics'
require 'log'

require 'yaml'

class MainThread

    def initialize
        I18n.load_path = Dir[File.join(File.dirname(__FILE__), '..', 'lang', '*.yml')]
        I18n.backend.load_translations
        I18n.default_locale = :de
        I18n.locale = config['locale'] unless ENV['LOCALE'].nil?

        configFilename  = case ENV['ICSBOT_ENV']
            when 'production'
                'prod.yml'
            when 'testing'
                'test.yml'
            else
                log("Unknown environment. Cannot load config. Terminating.")
                exit
            end
        self.loadConfig(File.join [File.dirname(__FILE__), '..', 'config', configFilename])
    end

    def loadConfig(configFile)
        @config = YAML.load_file(configFile)
    end

    def run
        data = DataStore.new(File.join(File.dirname(__FILE__), '..', @config['db_path']))
        events = ICS::Calendar.new
        events.loadEvents(ICS::FileParser::parseICS(File.join(File.dirname(__FILE__), '..', @config['ics_path'])))
        bot = Bot.new(@config['bot_token'], data, events)
        
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
        end
        
        botThreadBlock = lambda do
            bot.run
        end
        
        Signal.trap("TERM") do
            execute = false
            log("Termination signal received")
            watchdog.stop
        end

        Signal.trap("INT") do
            execute = false
            log("Interrupt signal received")
            watchdog.stop
        end
        
        watchdog.watch([{
            name: 'Bot',
            thr: botThreadBlock
        }, {
            name: 'Database',
            thr: databaseThreadBlock
        }, {
            name: 'Event',
            thr: eventThreadBlock
        }])

        execute = true
        

        while(execute) do
            sleep 1
        end
    end
end
