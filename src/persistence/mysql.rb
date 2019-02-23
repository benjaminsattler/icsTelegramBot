# frozen_string_literal: true

require 'log'
require 'persistence/persistence'
require 'mysql2'

##
# This class bundles mysql persistence functionality
class Mysql < Persistence
  @db = nil
  @subscribers = nil

  def initialize(host, port, username, password, database)
    @db = Mysql2::Client.new(
      host: host,
      username: username,
      password: password,
      port: port,
      database: database
    )
    @subscribers = @db.query('SELECT * from subscribers')
                      .map do |sub|
      Mysql.fix_database_object(sub)
    end
  end

  def add_subscriber(sub)
    @subscribers.push(sub)
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
    @subscribers.reject! do |subscriber|
      (subscriber[:telegram_id] == sub[:telegram_id]) &&
        (subscriber[:eventlist_id] == sub[:eventlist_id])
    end
    e_telegram_id = sub[:telegram_id]
    e_eventlist_id = sub[:eventlist_id]
    @db.query(
      'DELETE FROM subscribers '\
      "WHERE telegram_id = #{e_telegram_id} AND "\
      "eventlist_id = #{e_eventlist_id}"
    )
  end

  def subscriber_by_id(id, eventlist = 1)
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
    @db
      .query(
        'SELECT * from subscribers '\
        "WHERE telegram_id = #{id}"
      )
      .map { |sub| Mysql.fix_database_object(sub) }
  end

  def all_subscribers(eventlist = 1)
    @db
      .query(
        'SELECT * from subscribers '\
        "WHERE eventlist_id = #{eventlist}"
      )
      .map { |sub| Mysql.fix_database_object(sub) }
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
    @db.query(
      'UPDATE subscribers SET '\
      "notificationday = #{day} " \
      "WHERE telegram_id = #{sub_id} AND "\
      "eventlist_id = #{eventlist_id}"
    )
  end

  def update_time(sub_id, eventlist_id, time)
    @db.query(
      'UPDATE subscribers SET '\
      "notificationtime = #{time} " \
      "WHERE telegram_id = #{sub_id} AND "\
      "eventlist_id = #{eventlist_id}"
    )
  end

  def add_calendar(calendar)
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
    calendars = {}
    @db.query('SELECT * FROM eventslists').each do |calendar|
      cal_fixed = Mysql.fix_database_calendar_object(calendar)
      calendars[cal_fixed[:calendar_id]] = cal_fixed
    end
    calendars
  end

  def escape(input)
    return nil if input.nil?

    @db.escape(input)
  end
end
