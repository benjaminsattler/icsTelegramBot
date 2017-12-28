require 'sqlite3'

class DataStore
    @db = nil
    @subscribers = nil

    def initialize(file)
        @db = SQLite3::Database.new file
        @db.execute <<-SQL
            create table IF NOT EXISTS subscribers (
                id INTEGER PRIMARY KEY,
                telegram_id int not null,
                notificationday int not null,
                notificationtime int not null
            );
            SQL
        @subscribers = @db.execute('SELECT * from subscribers').map { |sub| DataStore.fixDatabaseObject(sub) }
    end

    def addSubscriber(sub)
        @subscribers.push(sub)
        notificationtime = sub[:notificationtime][:hrs] * 100 + sub[:notificationtime][:min]
        @db.execute('INSERT INTO subscribers(telegram_id, notificationday, notificationtime) VALUES(?, ?, ?)', [sub[:telegram_id], sub[:notificationday], notificationtime])
    end

    def removeSubscriber(id)
        @subscribers.reject! { |subscriber| subscriber[:telegram_id] == id }
        @db.execute('DELETE FROM subscribers WHERE telegram_id = ? LIMIT 1', [id])
    end

    def getSubscriberById(id)
        @subscribers
            .select { |subscriber| subscriber[:telegram_id] == id }
            .first
    end

    def getAllSubscribers()
        @subscribers
    end

    def self.fixDatabaseObject(sub)
        notificationhour = sub[3] / 100
        notificationminute = sub[3] % 100
        {telegram_id: sub[1], notificationday:sub[2], notificationtime: {hrs: notificationhour, min: notificationminute}, notifiedEvents: []}
    end

    def updateSubscriber(sub)
        @subscribers = @subscribers.map { |subscriber|
            subscriber[:notificationday] = sub[:notificationday] if sub[:telegram_id] == subscriber[:telegram_id]
            subscriber[:notificationtime][:hrs] = sub[:notificationtime][:hrs] if sub[:telegram_id] == subscriber[:telegram_id]
            subscriber[:notificationtime][:min] = sub[:notificationtime][:min] if sub[:telegram_id] == subscriber[:telegram_id]
            subscriber
        }
    end

    def flush
        unless @subscribers.nil?
            @subscribers.each do |subscriber|
                notificationtime = subscriber[:notificationtime][:hrs] * 100 + subscriber[:notificationtime][:min]
                @db.execute('UPDATE subscribers SET notificationday = ?, notificationtime = ? WHERE telegram_id = ? LIMIT 1', subscriber[:notificationday], notificationtime, subscriber[:telegram_id])
            end
        end
    end
end