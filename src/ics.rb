# frozen_string_literal: true

require 'log'
require 'Date'

##
# This module represents classes used for parsing,
# storing, and handling *.ics calendar files.
module ICS
  ##
  # This class provides an ics parser class which
  # is able to return ruby event objects when given
  # an *.ics file.
  class FileParser
    def self.parse_ics_date(date)
      Date.strptime(date, '%Y%m%d')
    end

    def self.clean_line(line)
      line.strip
    end

    def self.split_line(line)
      parts = line.split(':')
      return nil, parts[0] if parts.length == 1
      [parts[0], parts[1]]
    end

    def self.parse_ics(file)
      File.open(file, 'r', external_encoding: Encoding::UTF_8) do |handle|
        ICS::FileParser.parse_string(handle.gets(nil))
      end
    end

    def self.parse_string(input)
      current_event = nil
      events = []
      input.each_line do |line|
        k, v = split_line(clean_line(line))
        case k
        when 'BEGIN'
          case v
          when 'VEVENT'
            if current_event.nil?
              current_event = ICS::Event.new
            else
              throw('Error: encountered new event'\
                    ' without closing previous event')
            end
          else
            log("Unknown BEGIN key #{v}")
          end
        when 'END'
          case v
          when 'VEVENT'
            if current_event.nil?
              throw('Error: encountered close event without opened one')
            else
              current_event.id = Random.new.rand(2**30 - 1)
              events.push(current_event)
              current_event = nil
            end
          else
            log("Unknown END key #{v}")
          end
        when 'SUMMARY'
          if current_event.nil?
            throw 'Error: event property found when in no active event'
          else
            current_event.summary = v
          end
        when 'DTSTART;VALUE=DATE'
          if current_event.nil?
            throw 'Error event property found when in no active event'
          else
            current_event.date = ICS::FileParser.parse_ics_date(v)
          end
        end
      end
      log("Found #{events.length} events.")
      events
    end
  end

  ##
  # Container class for storing information about
  # an ics calendar event.
  class Event
    attr_accessor :date, :summary, :id, :calendar_id
  end

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
