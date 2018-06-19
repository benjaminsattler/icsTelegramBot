# frozen_string_literal: true

module Events
  ##
  # This class holds a collection of ics calendar events.
  class Calendar
    def initialize
      @events = []
    end

    def load_events(events)
      @events = events.sort_by { |event| [event.date.year, event.date.yday] }
    end

    def events(count = -1)
      result = nil
      events = @events.reject { |event| event.date <= Date.today }
      result = events.take(count) if count > -1
      result = events if count == -1
      result
    end

    def add_event(event)
      @events.push(event)
    end

    def least_recent_event
      @events.last
    end
  end
end
