# frozen_string_literal: true

require 'log'
require 'sqlite3'
require 'persistence/persistence'

##
# This class bundles sqlite persistence functionality
class Sqlite < Persistence
  @db = nil
  @subscribers = nil

  def initialize(file)
    @db = SQLite3::Database.new file
    @subscribers = @db
                   .execute('SELECT * from subscribers')
                   .map { |sub| Sqlite.fix_database_object(sub) }
  end

  def add_subscriber(sub)
    @subscribers.push(sub)
    notificationtime = sub[:notificationtime][:hrs] * 100
    notificationtime += sub[:notificationtime][:min]
    @db.execute(
      'INSERT INTO subscribers('\
      'telegram_id, '\
      'notificationday, '\
      'notificationtime, '\
      'eventlist_id'\
      ') VALUES('\
      '?, ?, ?, ?'\
      ')',
      [
        sub[:telegram_id],
        sub[:notificationday],
        notificationtime,
        sub[:eventlist_id]
      ]
    )
  end

  def remove_subscriber(sub)
    @subscribers.reject! do |subscriber|
      (subscriber[:telegram_id] == sub[:telegram_id]) &&
        (subscriber[:eventlist_id] == sub[:eventlist_id])
    end
    @db.execute(
      'DELETE FROM subscribers '\
      'WHERE telegram_id = ? AND '\
      'eventlist_id = ?',
      [
        sub[:telegram_id],
        sub[:eventlist_id]
      ]
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
    notificationhour = sub[3] / 100
    notificationminute = sub[3] % 100
    {
      telegram_id: sub[1],
      notificationday: sub[2],
      eventlist_id: sub[4],
      notificationtime: {
        hrs: notificationhour,
        min: notificationminute
      },
      notifiedEvents: []
    }
  end

  def self.fix_database_calendar_object(sub)
    { calendar_id: sub[0], description: sub[1], ics_path: sub[2] }
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
      @db.execute(
        'UPDATE subscribers SET '\
        'notificationday = ?, ' \
        'notificationtime = ? ' \
        'WHERE telegram_id = ? AND '\
        'eventlist_id = ?',
        subscriber[:notificationday],
        notificationtime,
        subscriber[:telegram_id],
        subscriber[:eventlist_id]
      )
    end
  end

  def calendars
    calendars = {}
    @db.execute('SELECT * FROM eventslists').each do |calendar|
      cal_fixed = Sqlite.fix_database_calendar_object(calendar)
      calendars[cal_fixed[:calendar_id]] = cal_fixed
    end
    calendars
  end
end
