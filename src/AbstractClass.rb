class AbstractClass
    def bot
        Container::get(:bot)
    end

    def dataStore()
        Container::get(:dataStore)
    end

    def calendars()
        Container::get(:calendars)
    end
end
