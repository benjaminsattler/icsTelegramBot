# frozen_string_literal: true

require 'log'
require 'date'
require 'events/event'
require 'open-uri'
require 'aws-sdk'

##
# This module represents classes used for parsing,
# storing, and handling *.ics calendar files.
module ICS
  ##
  # This class provides an ics parser class which
  # is able to return ruby event objects when given
  # an *.ics file.
  class FileParser
    def self.supported?(filename)
      # rubocop:disable Style/DoubleNegation
      !!/\.ics$/i.match(filename)
      # rubocop:enable Style/DoubleNegation
    end

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
              current_event = Events::Event.new
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
            end
            generated_id = Random.new.rand(2**30 - 1)
            current_event.id = generated_id if current_event.id.nil?
            events.push(current_event)
            current_event = nil
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
        when 'UID'
          if current_event.nil?
            throw 'Error: event property found when in no active event'
          else
            current_event.id = v
          end
        end
      end
      log("Found #{events.length} events.")
      events
    end
  end
end
