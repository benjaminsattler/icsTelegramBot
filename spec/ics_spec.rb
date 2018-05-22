require 'ics'
require 'Tempfile'
require 'Date'

RSpec.describe 'Module ICS' do
    before(:all) do
        $stdout = File.open(File::NULL, 'w')
    end

    describe 'FileParser' do
        before(:each) do
            @icsFile = <<~ICSEND
            BEGIN:VCALENDAR
            PRODID:-//Grafik-Partner GmbH//Muellmax 7.0 MIMEDIR//EN
            VERSION:2.0
            METHOD:PUBLISH
            BEGIN:VEVENT
            DTSTART;VALUE=DATE:20180216
            DTEND;VALUE=DATE:20180217
            DESCRIPTION:Wissenschaftsstadt Darmstadt\n
                Eigenbetrieb für kommunale Aufgaben und Dienstleistungen (EAD)\n
                vertreten durch die Betriebsleitung\n
                Sensfelder Weg 33\n
                64293 Darmstadt\n
                \n
                Service-Telefonnummer: 06151 / 13 46 000\n
                Fax: 06151 / 1346 393\n
                mailto:ead@darmstadt.de\n
                http://www.ead.darmstadt.de
            LOCATION:64287 Darmstadt-Innenstadt, Soderstraße 36-Ende, 39-Ende
            TRANSP:TRANSPARENT
            SEQUENCE:0
            UID:15183587251@muellmax.de
            DTSTAMP:20180211T141845Z
            SUMMARY:EAD Restabfall wöchentliche Leerung
            CLASS:PUBLIC
            CREATED:20180112T145036Z
            LAST-MODIFIED:20180112T145036Z
            URL:http://www.muellmax.de
            END:VEVENT
            BEGIN:VEVENT
            DTSTART;VALUE=DATE:20180223
            DTEND;VALUE=DATE:20180224
            DESCRIPTION:Wissenschaftsstadt Darmstadt\n
                Eigenbetrieb für kommunale Aufgaben und Dienstleistungen (EAD)\n
                vertreten durch die Betriebsleitung\n
                Sensfelder Weg 33\n
                64293 Darmstadt\n
                \n
                Service-Telefonnummer: 06151 / 13 46 000\n
                Fax: 06151 / 1346 393\n
                mailto:ead@darmstadt.de\n
                http://www.ead.darmstadt.de
            LOCATION:64287 Darmstadt-Innenstadt, Soderstraße 36-Ende, 39-Ende
            TRANSP:TRANSPARENT
            SEQUENCE:0
            UID:15183587252@muellmax.de
            DTSTAMP:20180211T141845Z
            SUMMARY:EAD Restabfall wöchentliche Leerung
            CLASS:PUBLIC
            CREATED:20180112T145036Z
            LAST-MODIFIED:20180112T145036Z
            URL:http://www.muellmax.de
            END:VEVENT
            END:VCALENDAR
            ICSEND
        end

        describe 'parseICSDate' do
            it 'should parse ICS Dates correctly' do
                actual = ICS::FileParser::parseICSDate '20180216'
                expect(actual).to be_instance_of Date
                expect(actual.to_s).to eq '2018-02-16'
            end
        end

        describe 'stripLine' do
            it 'should remove leading whitespace' do
                actual = ICS::FileParser::cleanLine '    foobar'
                expect(actual).to eq 'foobar'
            end

            it 'should remove trailing whitespace' do
                actual = ICS::FileParser::cleanLine 'foobar     '
                expect(actual).to eq 'foobar'
            end

            it 'should remove leading and trailing whitespace' do
                actual = ICS::FileParser::cleanLine '   foobar     '
                expect(actual).to eq 'foobar'
            end
        end

        describe 'splitLine' do
            it 'should return a well formed hash' do
                actual = ICS::FileParser::splitLine 'foo:bar' 
                expect(actual).to be_instance_of Hash
                expect(actual).to have_key :k
                expect(actual).to have_key :v
            end

            it 'should properly split a two segment line' do
                actual = ICS::FileParser::splitLine 'foo:bar'
                expect(actual[:k]).to eq 'foo'
                expect(actual[:v]).to eq 'bar'
            end

            it 'should properly split a one segmnent line' do
                actual = ICS::FileParser::splitLine 'foobar'
                expect(actual[:k]).to be_nil
                expect(actual[:v]).to eq 'foobar'
            end

            it 'should gracefully handle an empty line' do
                actual = ICS::FileParser::splitLine ''
                expect(actual[:k]).to be_nil
                expect(actual[:v]).to be_nil
            end
        end

        describe 'parseICS' do
            
            before(:each) do
                @filePath = Tempfile.new('', './tmp')
                Dir.mkdir(File.dirname(@filePath)) unless Dir.exists?(File.dirname(@filePath))
                File.open(@filePath, 'w') { |handle| handle.write @icsFile }
            end

            after(:each) do
                File.unlink @filePath
            end

            it 'should return a list of events' do
                actual = ICS::FileParser::parseICS @filePath
                expect(actual).to be_instance_of Array
                expect(actual.length).to eq 2
                expect(actual).to all(be_instance_of(ICS::Event))
            end

            it 'should correctly parse events' do
                actual = ICS::FileParser::parseICS @filePath
                expect(actual[0].date).to be_instance_of Date
                expect(actual[0].date.day).to eq(16)
                expect(actual[0].date.month).to eq(2)
                expect(actual[0].date.year).to eq(2018)
                expect(actual[0].summary).to eq('EAD Restabfall wöchentliche Leerung')
                expect(0..2**30-1).to cover actual[0].id
            end
        end
    end

    describe 'Calendar' do

        before(:each) do
            @calendar = ICS::Calendar.new
            @ev1 = ICS::Event.new
            @ev1.date = Date.today + 10
            @ev1.summary = 'foobar'
            @ev1.id = 42
            @ev1.calendar_id = 1
            @ev2 = ICS::Event.new
            @ev2.date = Date.today + 1
            @ev2.summary = 'bazinga'
            @ev2.id = 4711
            @ev2.calendar_id = 0
        end

        describe 'loadEvents' do
            it 'should load events in the calendar' do
                expect(@calendar.getEvents).to match_array []
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents
                expect(actual).to match_array [@ev1, @ev2]
            end
        end

        describe 'getEvents' do

            it 'should return a list of events' do
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents
                expect(actual).to be_instance_of Array
                expect(actual[0]).to be_instance_of ICS::Event
                expect(actual[1]).to be_instance_of ICS::Event
            end

            it 'should not return past events' do
                ev3 = ICS::Event.new
                ev3.date = Date.today -1
                ev3.summary = 'foxymusic'
                ev3.id = 90210
                ev3.calendar_id = 5
                @calendar.loadEvents [@ev1, @ev2, ev3]
                actual = @calendar.getEvents
                expect(actual.length).to eq(2)
            end

            it 'should not return events of today' do
                ev3 = ICS::Event.new
                ev3.date = Date.today
                ev3.summary = 'foxymusic'
                ev3.id = 90210
                ev3.calendar_id = 5
                @calendar.loadEvents [@ev1, @ev2, ev3]
                actual = @calendar.getEvents
                expect(actual.length).to eq(2)
            end

            it ('should sort events from soonest to latest') do
                ev3 = ICS::Event.new
                ev3.date = Date.today + 15
                ev3.summary = 'foxymusic'
                ev3.id = 90210
                ev3.calendar_id = 5
                @calendar.loadEvents [ev3, @ev2, @ev1]
                actual = @calendar.getEvents
                expect(actual[0]).to eq @ev2
                expect(actual[1]).to eq @ev1
                expect(actual[2]).to eq ev3
            end

            it 'should return all events when count is -1' do
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents -1
                expect(actual.length).to eq(2)
            end

            it 'should return all events when count is missing' do
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents -1
                expect(actual.length).to eq(2)
            end

            it 'should return the specified number of events when count is present' do
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents 2
                expect(actual.length).to eq(2)
                actual = @calendar.getEvents 1
                expect(actual.length).to eq(1)
                actual = @calendar.getEvents 0
                expect(actual.length).to eq(0)
            end

            it 'should return all events when count is bigger than number of events' do
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents 10
                expect(actual.length).to eq(2)
            end
        end

        describe 'addEvent' do
            it 'should add the given event to the calendar' do
                ev3 = ICS::Event.new
                ev3.date = Date.today + 1
                ev3.summary = 'foxymusic'
                ev3.id = 90210
                ev3.calendar_id = 5
                @calendar.loadEvents [@ev1, @ev2]
                actual = @calendar.getEvents
                expect(actual).not_to include ev3
                expect(actual.length).to eq(2)
                @calendar.addEvent ev3
                actual = @calendar.getEvents
                expect(actual).to include ev3
                expect(actual.length).to eq(3)
            end
        end

        describe 'getLeastRecentEven' do
            it 'should return the latest event' do
                ev3 = ICS::Event.new
                ev3.date = Date.today + 12
                ev3.summary = 'foxymusic'
                ev3.id = 90210
                ev3.calendar_id = 5
                @calendar.loadEvents [ev3, @ev1, @ev2]
                actual = @calendar.getLeastRecentEvent
                expect(actual).to eq(ev3)
            end

            it 'should return nil when no events are stored in the calendar' do
                actual = @calendar.getLeastRecentEvent
                expect(actual).to be_nil
            end
        end
    end
end
