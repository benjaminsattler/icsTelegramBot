require_relative './data'
require_relative './bot'
require_relative './ics'
require_relative './watchdog'
require_relative './log'

class Server

    attr_reader :options
    def initialize(options)
        @options = options
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
