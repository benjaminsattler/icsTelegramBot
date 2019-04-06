# frozen_string_literal: true

require 'log'
require 'persistence/persistence'
require 'mysql2'

##
# This class bundles mysql persistence functionality
class Mysql < Persistence
  @hostname = nil
  @port = nil
  @username = nil
  @password = nil
  @databasename = nil

  @db = nil

  def initialize(host, port, username, password, database)
    @hostname = host
    @port = port
    @username = username
    @password = password
    @databasename = database
  end

  def reconnect
    return if !@db.nil? && !@db.closed?

    log('Reconnect to database')
    @db = Mysql2::Client.new(
      host: @hostname,
      username: @username,
      password: @password,
      port: @port,
      database: @databasename
    )
  end

  def connected?
    !@db.nil? && !@db.closed?
  end

  def add_subscriber(sub)
    reconnect unless connected?
    notificationtime = sub[:notificationtime][:hrs] * 100
    notificationtime += sub[:notificationtime][:min]
    e_notification_time = notificationtime
    e_telegram_id = sub[:telegram_id]
    e_notification_day = sub[:notificationday]
    e_eventlist = sub[:eventlist_id]
    @db.query(
      'INSERT INTO subscribers('\
      'telegram_id, '\
      'notificationday, '\
      'notificationtime, '\
      'eventlist_id'\
      ') VALUES('\
      "#{e_telegram_id},"\
      "#{e_notification_day},"\
      "#{e_notification_time},"\
      "#{e_eventlist}"\
      ')'
    )
  end

  def remove_subscriber(sub)
    reconnect unless connected?
    e_telegram_id = sub[:telegram_id]
    e_eventlist_id = sub[:eventlist_id]
    @db.query(
      'DELETE FROM subscribers '\
      "WHERE telegram_id = #{e_telegram_id} AND "\
      "eventlist_id = #{e_eventlist_id}"
    )
  end

  def subscriber_by_id(id, eventlist = 1)
    reconnect unless connected?
    @db
      .query(
        'SELECT * from subscribers '\
        "WHERE telegram_id = #{id} AND "\
        "eventlist_id = #{eventlist}"
      )
      .map { |sub| Mysql.fix_database_object(sub) }
      .first
  end

  def subscriptions_for_id(id)
    reconnect unless connected?
    @db
      .query(
        'SELECT * from subscribers '\
        "WHERE telegram_id = #{id}"
      )
      .map { |sub| Mysql.fix_database_object(sub) }
  end

  def all_subscribers(eventlist = nil)
    reconnect unless connected?
    if eventlist.nil?
      @db
        .query('SELECT DISTINCT * from subscribers')
        .map { |sub| Mysql.fix_database_object(sub) }
    else
      @db
        .query(
          'SELECT * from subscribers '\
          "WHERE eventlist_id = #{eventlist}"
        )
        .map { |sub| Mysql.fix_database_object(sub) }
    end
  end

  def self.fix_database_object(sub)
    notificationhour = sub['notificationtime'] / 100
    notificationminute = sub['notificationtime'] % 100
    {
      telegram_id: sub['telegram_id'],
      notificationday: sub['notificationday'],
      eventlist_id: sub['eventlist_id'],
      notificationtime: {
        hrs: notificationhour,
        min: notificationminute
      },
      notifiedEvents: []
    }
  end

  def self.fix_database_calendar_object(sub)
    {
      calendar_id: sub['id'],
      description: sub['display_name'],
      ics_path: sub['filename']
    }
  end

  def update_day(sub_id, eventlist_id, day)
    reconnect unless connected?
    @db.query(
      'UPDATE subscribers SET '\
      "notificationday = #{day} " \
      "WHERE telegram_id = #{sub_id} AND "\
      "eventlist_id = #{eventlist_id}"
    )
  end

  def update_time(sub_id, eventlist_id, time)
    reconnect unless connected?
    @db.query(
      'UPDATE subscribers SET '\
      "notificationtime = #{time} " \
      "WHERE telegram_id = #{sub_id} AND "\
      "eventlist_id = #{eventlist_id}"
    )
  end

  def add_calendar(calendar)
    reconnect unless connected?
    escaped_filename = escape(calendar[:filename])
    escaped_display_name = escape(calendar[:display_name])
    @db.query(
      'INSERT INTO eventslists('\
      'display_name, '\
      'filename, '\
      'owner'\
      ') VALUES('\
      "'#{escaped_display_name}', "\
      "'#{escaped_filename}', "\
      "#{calendar[:owner]}"\
      ')'
    )
  end

  def calendars
    reconnect unless connected?
    calendars = {}
    @db.query('SELECT * FROM eventslists').each do |calendar|
      cal_fixed = Mysql.fix_database_calendar_object(calendar)
      calendars[cal_fixed[:calendar_id]] = cal_fixed
    end
    calendars
  end

  def escape(input)
    reconnect unless connected?
    return nil if input.nil?

    @db.escape(input)
  end

  def add_to_message_log(message)
    reconnect unless connected?
    timestamp = Time.at(
      message[:message_timestamp]
    )
    @db.query(
      'INSERT INTO message_log('\
      'telegram_id, '\
      'msg_id, '\
      'message_timestamp, '\
      'i18nkey, '\
      'i18nparams '\
      ') VALUES('\
      "#{message[:telegram_id]}, "\
      "#{message[:msg_id]}, "\
      "'#{timestamp.strftime('%Y-%m-%d %H:%M:%S')}', "\
      "'#{message[:i18nkey]}', "\
      "'#{message[:i18nparams]}' "\
      ')'
    )
  end

  def message_from_log(message_id)
    reconnect unless connected?
    escaped_message_id = escape(message_id.to_s)
    result = []
    @db
      .query(
        'SELECT * from message_log '\
        "WHERE msg_id = #{escaped_message_id}"
      )
      .each { |res| result.push(res) }
    result
  end

  def add_to_notification_log(notification, timestamp)
    reconnect unless connected?
    escaped_event_id = escape(notification.event.id.chomp)
    query = 'INSERT INTO notification_log('\
      'telegram_id, '\
      'event_id, '\
      'calendar_id, '\
      'message_timestamp '\
      ') VALUES('\
      "#{notification.id_recv}, "\
      "'#{escaped_event_id}', "\
      "#{notification.calendar[:calendar_id]}, "\
      "'#{Time.at(timestamp).strftime('%Y-%m-%d %H:%M:%S')}'"\
      ')'
    @db.query(
      query
    )
  end

  def notification?(sub, calendar, event)
    escaped_sub_id = escape(sub[:telegram_id].to_s)
    escaped_event_id = escape(event.id.chomp)
    query = 'SELECT * FROM notification_log '\
      "WHERE telegram_id = #{escaped_sub_id} AND "\
      "event_id = '#{escaped_event_id}' AND "\
      "calendar_id = #{calendar[:calendar_id]}"
    count = @db.query(
      query
    ).count
    count.positive?
  end
end
