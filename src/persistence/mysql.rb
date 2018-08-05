# frozen_string_literal: true

require 'log'
require 'persistence/persistence'
require 'mysql2'

##
# This class bundles sqlite persistence functionality
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
    @subscribers = []
    @db
      .query('SELECT * from subscribers')
      .each { |sub| @subscribers.push(Mysql.fix_database_object(sub)) }
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
    @subscribers
      .select do |subscriber|
        subscriber[:telegram_id] == id && subscriber[:eventlist_id] == eventlist
      end
      .first
  end

  def subscriptions_for_id(id)
    @subscribers
      .select { |subscriber| subscriber[:telegram_id] == id }
  end

  def all_subscribers(eventlist = 1)
    @subscribers.select { |subscriber| subscriber[:eventlist_id] == eventlist }
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

  def update_subscriber(sub)
    @subscribers = @subscribers.map do |subscriber|
      if  (sub[:telegram_id] == subscriber[:telegram_id]) &&
          (subscriber[:eventlist_id] == sub[:eventlist_id])
        subscriber[:notificationday] = sub[:notificationday]
      end
      if  (sub[:telegram_id] == subscriber[:telegram_id]) &&
          (subscriber[:eventlist_id] == sub[:eventlist_id])
        subscriber[:notificationtime][:hrs] = sub[:notificationtime][:hrs]
      end
      if  (sub[:telegram_id] == subscriber[:telegram_id]) &&
          (subscriber[:eventlist_id] == sub[:eventlist_id])
        subscriber[:notificationtime][:min] = sub[:notificationtime][:min]
      end
      subscriber
    end
  end

  def flush
    return if @subscribers.nil?
    @subscribers.each do |subscriber|
      notificationtime = subscriber[:notificationtime][:hrs] * 100
      notificationtime += subscriber[:notificationtime][:min]
      e_notification_time = notificationtime
      e_notification_day = subscriber[:notificationday]
      e_telegram_id = subscriber[:telegram_id]
      e_eventlist_id = subscriber[:eventlist_id]
      @db.query(
        'UPDATE subscribers SET '\
        "notificationday = #{e_notification_day}, " \
        "notificationtime = #{e_notification_time} " \
        "WHERE telegram_id = #{e_telegram_id} AND "\
        "eventlist_id = #{e_eventlist_id}"
      )
    end
  end

  def calendars
    calendars = {}
    @db.query('SELECT * FROM eventslists').each do |calendar|
      cal_fixed = Mysql.fix_database_calendar_object(calendar)
      calendars[cal_fixed[:calendar_id]] = cal_fixed
    end
    calendars
  end
end
