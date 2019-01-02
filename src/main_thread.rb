# frozen_string_literal: true

require 'watchdog'
require 'bot'
require 'persistence/factory'
require 'ics'
require 'events/calendar'
require 'log'
require 'container'

require 'configuration/environment_configuration'

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
    I18n.locale = ENV['LOCALE'] unless ENV['LOCALE'].nil?

    env = ENV['ICSBOT_ENV'].nil? ? 'testing' : ENV['ICSBOT_ENV']
    @is_running = true

    unless %w[production development testing].include?(env)
      log("Unknown environment #{env}. Terminating...")
      exit
    end

    log("Running in #{env.upcase} environment")
    @config = EnvironmentConfiguration.new
  end

  def run
    data = Factory.new(@config).get(@config.get('persistence'))
    bot = Bot.new(
      @config.get('bot_token'),
      @config.get('admin_users').split(/:/)
    )
    @watchdog = Watchdog.new

    Container.set(:bot, bot)
    Container.set(:calendars, [])
    Container.set(:dataStore, data)
    Container.set(:watchdog, @watchdog)

    event_thread_block = lambda do
      begin
        calendars = Container.get(:dataStore).calendars
        Container.set(:calendars, calendars)
        calendars.each_value do |calendar_desc|
          events = Events::Calendar.new
          events.load_events(
            ICS::FileParser.parse_ics(
              calendar_desc[:ics_path]
            )
          )
          calendar_desc[:eventlist] = events
          calendar_desc
        end

        until Thread.current[:stop]
          calendars.each_value do |calendar|
            calendar[:eventlist].events.each do |event|
              bot.notify(calendar[:calendar_id], event)
            end
            sleep 5
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
          seconds = @config.get('flush_interval').to_i
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
                           name: 'bot',
                           thr: bot_thread_block
                         }, {
                           name: 'database',
                           thr: database_thread_block
                         }, {
                           name: 'event',
                           thr: event_thread_block
                         }])

    @is_running = true

    th.join
  end

  def stop
    @watchdog.stop
  end
end
