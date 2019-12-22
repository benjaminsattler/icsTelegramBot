# frozen_string_literal: true

require 'watchdog'
require 'bot'
require 'persistence/factory'
require 'ics'
require 'events/calendar'
require 'log'
require 'container'
require 'telegram_api'
require 'statistics'
require 'message_log'

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

    @config = EnvironmentConfiguration.new
    Container.set('logging', Logging.new(@config))
    unless %w[production development testing].include?(env)
      log("Unknown environment #{env}. Terminating...")
      exit
    end

    log("Running in #{env.upcase} environment")
  end

  def run
    data = Factory.new(@config).get(@config.get('persistence'))
    Container.set(:dataStore, data)
    bot = Bot.new(
      @config.get('bot_token'),
      @config.get('admin_users').split(/:/),
      Statistics.new,
      MessageLog.new(data)
    )
    Container.set(:bot, bot)
    @watchdog = Watchdog.new

    Container.set(:calendars, {})
    Container.set(:watchdog, @watchdog)

    event_thread_block = lambda do
      begin
        calendars = Container.get(:dataStore).calendars
        Container.set(:calendars, calendars)
        s3 = Aws::S3::Resource.new.client
        calendars.each_value do |calendar_desc|
          resp = s3.get_object(
            bucket: ENV['AWS_S3_BUCKET'],
            key: calendar_desc[:ics_path],
            response_content_encoding: 'UTF-8'
          )
          events = Events::Calendar.new
          events.load_events(
            ICS::FileParser.parse_string(
              resp.body.read.force_encoding('UTF-8')
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

    bot_thread_block = lambda do
      begin
        bot.run TelegramApi
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
