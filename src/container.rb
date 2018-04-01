class Container
    @@bot = nil
    @@calendars = nil
    @@dataStore = nil

    def self::get(reference)
        if reference === 'bot' then
            return @@bot
        elsif reference === 'calendars' then
            return @@calendars
        elsif reference === 'datastore' then
            return @@dataStore
        end
    end

    def self::set(reference, value)
        if reference === 'bot' then
            @@bot = value
        elsif reference === 'calendars' then
            @@calendars = value
        elsif reference === 'datastore' then
            @@dataStore = value
        end
    end
end
