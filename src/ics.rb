require 'log'

module ICS
    class FileParser

        def self.parseICSDate(dateString)
            Date.strptime(dateString, '%Y%m%d')
        end

        def self.cleanLine(line)
            line.strip
        end
        
        def self.splitLine(line)
            parts = line.split(':')
            if parts.length == 1
                {k: nil, v: parts[0]}
            else
                {k:parts[0], v: parts[1]}
            end
        end

        def self.parseICS(file)
            File.open(file, 'r', external_encoding:Encoding::UTF_8) do |file|
                currentEvent = nil
                events = []
                while(line = file.gets) do
                    line = self.cleanLine(line)
                    line = self.splitLine(line)
                    k = line[:k]
                    v = line[:v]
                    case k
                    when 'BEGIN'
                        case v
                        when 'VEVENT'
                            if (currentEvent.nil?) then
                                currentEvent = ICS::Event.new
                            else
                                throw('Error: encountered new event without closing previous event')
                            end
                        else
                            log("Unknown BEGIN key #{v}")
                        end
                    when 'END'
                        case v
                        when 'VEVENT'
                            if (currentEvent.nil?) then
                                throw('Error: encountered close event without opened one')
                            else
                                currentEvent.id = Random.new.rand(2**30-1)
                                events.push(currentEvent);
                                currentEvent = nil;
                            end
                        else
                        log("Unknown END key #{v}")
                        end
                    when 'SUMMARY'
                        if (currentEvent.nil?) then
                            throw 'Error: event property found when in no active event'
                        else
                            currentEvent.summary = v
                        end
                    when 'DTSTART;VALUE=DATE'
                        if (currentEvent.nil?) then
                            throw 'Error event property found when in no active event'
                        else
                            currentEvent.date = ICS::FileParser::parseICSDate(v)
                        end
                    end
                end
                log("Found #{events.length} events.")
                events
            end
        end
    end

    class Event
        attr_accessor :date, :summary, :id
    end

    class Calendar
        @events

        def getDate()
            Date.today
        end

        def loadEvents(events)
            @events = events.sort_by { |event| [event.date.year, event.date.yday] }
        end

        def getEvents(count = -1)
            result = nil
            events = @events.reject { |event| event.date <= getDate() }
            result = events.take(count) if count > -1
            result = events if count == -1
            result
        end
        
        def addEvent(event)
            @events.push(event)
        end
        
        def getLeastRecentEvent
            @events.last
        end
        
    end
end
