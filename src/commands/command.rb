class Command

    @bot = nil
    @dataStore = nil
    @calendars = nil
    def process(msg, userid, chatid, silent)
        raise NotImplementedError
    end
    
    def setBot(bot)
        @bot = bot
        return self
    end

    def setDataStore(dataStore)
        @dataStore = dataStore
        return self
    end

    def setCalendars(calendars)
        @calendars = calendars
        return self
    end
end