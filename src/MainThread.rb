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

    unless %w[production testing].include?(env)
      log("Unknown environment #{env}. Terminating...")
      exit
    end

    log("Running in #{env.upcase} environment")
    configFilename = case env
                     when 'production'
                       'prod.yml'
                     when 'testing'
                       'test.yml'
        end
    loadConfig(File.join([File.dirname(__FILE__), '..', 'config', configFilename]))
  end

  def loadConfig(configFile)
    @config = YAML.load_file(configFile)
  end

  def run
    data = DataStore.new(File.join(File.dirname(__FILE__), '..', @config['db_path']))
    calendars = data.getCalendars.each_value do |calendar_desc|
      events = ICS::Calendar.new
      events.loadEvents(ICS::FileParser.parseICS(File.join(File.dirname(__FILE__), '..', calendar_desc[:ics_path])))
      calendar_desc[:eventlist] = events
      calendar_desc
    end
    bot = Bot.new(@config['bot_token'], @config['admin_users'])

    Container.set(:bot, bot)
    Container.set(:calendars, calendars)
    Container.set(:dataStore, data)
    @watchdog = Watchdog.new
    eventThread = nil
    databaseThread = nil
    botThread = nil

    eventThreadBlock = lambda do
      begin
        until Thread.current[:stop]
          calendars.each_value do |calendar|
            calendar[:eventlist].getEvents.each do |event|
              bot.notify(calendar[:calendar_id], event)
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
        while run
          seconds = @config['flush_interval']
          while seconds > 0 && run
            sleep 1
            seconds -= 1
            run = false if Thread.current[:stop]
          end
          log('Syncing database...')
          data.flush
          log('Syncing done...')
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

    Signal.trap('TERM') do
      @isRunning = false
      log('Termination signal received')
      stop
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

    sleep 1 while @isRunning
  end

  def stop
    @watchdog.stop
  end
end
