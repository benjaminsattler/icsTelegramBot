# frozen_string_literal: true

require 'watchdog'
require 'bot'
require 'persistence/data'
require 'ics'
require 'events/calendar'
require 'log'
require 'container'

require 'yaml'

##
# This class represents the main thread which
# is responsible for spawing all other threads.
# This is our entry point to the program.
class MainThread
  @watchdog = nil
  @is_running = false
  @config = nil

  def initialize
    I18n.load_path = Dir[File.join(
      File.dirname(__FILE__),
      '..',
      'lang',
      '*.yml'
    )]
    I18n.backend.load_translations
    I18n.default_locale = :de
    I18n.locale = config['locale'] unless ENV['LOCALE'].nil?

    env = ENV['ICSBOT_ENV'].nil? ? 'testing' : ENV['ICSBOT_ENV']
    @is_running = true

    unless %w[production testing].include?(env)
      log("Unknown environment #{env}. Terminating...")
      exit
    end

    log("Running in #{env.upcase} environment")
    config_filename = case env
                      when 'production'
                        'prod.yml'
                      when 'testing'
                        'test.yml'
                      end
    load_config(
      File.join(
        [
          File.dirname(__FILE__),
          '..',
          'config',
          config_filename
        ]
      )
    )
  end

  def load_config(config_file)
    @config = YAML.load_file(config_file)
  end

  def run
    data = DataStore.new(
      File.join(
        File.dirname(__FILE__),
        '..',
        @config['db_path']
      )
    )
    calendars = data.calendars.each_value do |calendar_desc|
      events = Events::Calendar.new
      events.load_events(
        ICS::FileParser.parse_ics(
          File.join(
            File.dirname(__FILE__),
            '..',
            calendar_desc[:ics_path]
          )
        )
      )
      calendar_desc[:eventlist] = events
      calendar_desc
    end
    bot = Bot.new(@config['bot_token'], @config['admin_users'])

    Container.set(:bot, bot)
    Container.set(:calendars, calendars)
    Container.set(:dataStore, data)
    @watchdog = Watchdog.new

    event_thread_block = lambda do
      begin
        until Thread.current[:stop]
          calendars.each_value do |calendar|
            calendar[:eventlist].events.each do |event|
              bot.notify(calendar[:calendar_id], event)
            end
            sleep 1
          end
        end
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
      end
    end

    database_thread_block = lambda do
      begin
        run = true
        while run
          seconds = @config['flush_interval']
          while seconds.positive? && run
            sleep 1
            seconds -= 1
            run = false if Thread.current[:stop]
          end
          log('Syncing database...')
          data.flush
          log('Syncing done...')
        end
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
      end
    end

    bot_thread_block = lambda do
      begin
        bot.run
      rescue StandardError => e
        puts e.inspect
        puts e.backtrace
      end
    end

    Signal.trap('TERM') do
      @is_running = false
      log('Termination signal received')
      stop
    end

    Signal.trap('SIGINT') do
      # cannot handle SIGINT, because the telegram gem is trapping
      # this signal. Instead, we can throw SIGTERM and can react on that
      Process.kill('TERM', Process.pid)
    end

    th = @watchdog.watch([{
                           name: 'Bot',
                           thr: bot_thread_block
                         }, {
                           name: 'Database',
                           thr: database_thread_block
                         }, {
                           name: 'Event',
                           thr: event_thread_block
                         }])

    @is_running = true

    th.join
  end

  def stop
    @watchdog.stop
  end
end
