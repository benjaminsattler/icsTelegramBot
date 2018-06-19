# frozen_string_literal: true

module Events
  ##
  # Container class for storing information about
  # an ics calendar event.
  class Event
    attr_accessor :date, :summary, :id, :calendar_id
  end
end
