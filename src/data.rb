require 'log'

require 'sqlite3'

class DataStore
  @db = nil
  @subscribers = nil

  def initialize(file)
    @db = SQLite3::Database.new file
    @subscribers = @db.execute('SELECT * from subscribers').map { |sub| DataStore.fixDatabaseObject(sub) }
  end

  def addSubscriber(sub)
    @subscribers.push(sub)
    notificationtime = sub[:notificationtime][:hrs] * 100 + sub[:notificationtime][:min]
    @db.execute('INSERT INTO subscribers(telegram_id, notificationday, notificationtime, eventlist_id) VALUES(?, ?, ?, ?)', [sub[:telegram_id], sub[:notificationday], notificationtime, sub[:eventlist_id]])
  end

  def removeSubscriber(sub)
    @subscribers.reject! { |subscriber| (subscriber[:telegram_id] == sub[:telegram_id]) && (subscriber[:eventlist_id] == sub[:eventlist_id]) }
    @db.execute('DELETE FROM subscribers WHERE telegram_id = ? AND eventlist_id = ?', [sub[:telegram_id], sub[:eventlist_id]])
  end

  def getSubscriberById(id, eventlist = 1)
    @subscribers
      .select { |subscriber| subscriber[:telegram_id] == id && subscriber[:eventlist_id] == eventlist }
      .first
  end

  def getSubscriptionsForId(id)
    @subscribers
      .select { |subscriber| subscriber[:telegram_id] == id }
  end

  def getAllSubscribers(eventlist = 1)
    @subscribers.select { |subscriber| subscriber[:eventlist_id] == eventlist }
  end

  def self.fixDatabaseObject(sub)
    notificationhour = sub[3] / 100
    notificationminute = sub[3] % 100
    { telegram_id: sub[1], notificationday: sub[2], eventlist_id: sub[4], notificationtime: { hrs: notificationhour, min: notificationminute }, notifiedEvents: [] }
  end

  def self.fixDatabaseCalendarObject(sub)
    { calendar_id: sub[0], description: sub[1], ics_path: sub[2] }
  end

  def updateSubscriber(sub)
    @subscribers = @subscribers.map do |subscriber|
      subscriber[:notificationday] = sub[:notificationday] if (sub[:telegram_id] == subscriber[:telegram_id]) && (subscriber[:eventlist_id] == sub[:eventlist_id])
      subscriber[:notificationtime][:hrs] = sub[:notificationtime][:hrs] if (sub[:telegram_id] == subscriber[:telegram_id]) && (subscriber[:eventlist_id] == sub[:eventlist_id])
      subscriber[:notificationtime][:min] = sub[:notificationtime][:min] if (sub[:telegram_id] == subscriber[:telegram_id]) && (subscriber[:eventlist_id] == sub[:eventlist_id])
      subscriber
    end
  end

  def flush
    unless @subscribers.nil?
      @subscribers.each do |subscriber|
        notificationtime = subscriber[:notificationtime][:hrs] * 100 + subscriber[:notificationtime][:min]
        @db.execute('UPDATE subscribers SET notificationday = ?, notificationtime = ? WHERE telegram_id = ? AND eventlist_id = ?', subscriber[:notificationday], notificationtime, subscriber[:telegram_id], subscriber[:eventlist_id])
      end
    end
  end

  def getCalendars
    calendars = {}
    @db.execute('SELECT * FROM eventslists').each do |calendar|
      cal_fixed = DataStore.fixDatabaseCalendarObject(calendar)
      calendars[cal_fixed[:calendar_id]] = cal_fixed
    end
    calendars
  end
end
