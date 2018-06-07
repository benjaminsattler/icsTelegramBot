# frozen_string_literal: true

require 'ics'
require 'Tempfile'
require 'Date'

RSpec.describe ICS do
  before(:all) do
    $stdout = File.open(File::NULL, 'w')
  end

  describe ICS::FileParser do
    let(:ics_file) do
      <<~ICSEND
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

    describe 'parse_ics_date' do
      it 'parses ICS Dates correctly' do
        actual = ICS::FileParser.parse_ics_date '20180216'
        expect(actual).to be_instance_of Date
        expect(actual.to_s).to eq '2018-02-16'
      end
    end

    describe 'stripLine' do
      it 'removes leading whitespace' do
        actual = ICS::FileParser.clean_line '    foobar'
        expect(actual).to eq 'foobar'
      end

      it 'removes trailing whitespace' do
        actual = ICS::FileParser.clean_line 'foobar     '
        expect(actual).to eq 'foobar'
      end

      it 'removes leading and trailing whitespace' do
        actual = ICS::FileParser.clean_line '   foobar     '
        expect(actual).to eq 'foobar'
      end
    end

    describe 'split_line' do
      it 'properlies split a two segment line' do
        actual_k, actual_v = ICS::FileParser.split_line 'foo:bar'
        expect(actual_k).to eq 'foo'
        expect(actual_v).to eq 'bar'
      end

      it 'properlies split a one segmnent line' do
        actual_k, actual_v = ICS::FileParser.split_line 'foobar'
        expect(actual_k).to be_nil
        expect(actual_v).to eq 'foobar'
      end

      it 'gracefullies handle an empty line' do
        actual_k, actual_v = ICS::FileParser.split_line ''
        expect(actual_k).to be_nil
        expect(actual_v).to be_nil
      end
    end

    describe 'parse_ics' do
      let(:file_path) { Tempfile.new }
      let(:dir_path) { File.dirname(file_path) }

      before do
        Dir.mkdir(dir_path) unless Dir.exist?(dir_path)
        File.open(file_path, 'w') { |handle| handle.write ics_file }
      end

      after do
        File.unlink file_path
      end

      it 'returns a list of events' do
        actual = ICS::FileParser.parse_ics file_path
        expect(actual).to be_instance_of Array
        expect(actual.length).to eq 2
        expect(actual).to all(be_instance_of(ICS::Event))
      end

      it 'correctlies parse events' do
        actual = ICS::FileParser.parse_ics file_path
        expect(actual[0].date).to be_instance_of Date
        expect(actual[0].date.day).to eq(16)
        expect(actual[0].date.month).to eq(2)
        expect(actual[0].date.year).to eq(2018)
        expect(actual[0].summary).to eq('EAD Restabfall wöchentliche Leerung')
        expect(0..2**30 - 1).to cover actual[0].id
      end
    end
  end

  describe ICS::Calendar do
    let(:calendar) { ICS::Calendar.new }
    let(:ev1) do
      e = ICS::Event.new
      e.date = Date.today + 10
      e.summary = 'foobar'
      e.id = 42
      e.calendar_id = 1
      e
    end
    let(:ev2) do
      e = ICS::Event.new
      e.date = Date.today + 1
      e.summary = 'bazinga'
      e.id = 4711
      e.calendar_id = 0
      e
    end

    describe 'load_events' do
      it 'loads events in the calendar' do
        expect(calendar.events).to match_array []
        calendar.load_events [ev1, ev2]
        actual = calendar.events
        expect(actual).to match_array [ev1, ev2]
      end
    end

    describe 'events' do
      it 'returns a list of events' do
        calendar.load_events [ev1, ev2]
        actual = calendar.events
        expect(actual).to be_instance_of Array
        expect(actual[0]).to be_instance_of ICS::Event
        expect(actual[1]).to be_instance_of ICS::Event
      end

      it 'does not return past events' do
        ev3 = ICS::Event.new
        ev3.date = Date.today(-1)
        ev3.summary = 'foxymusic'
        ev3.id = 90_210
        ev3.calendar_id = 5
        calendar.load_events [ev1, ev2, ev3]
        actual = calendar.events
        expect(actual.length).to eq(2)
      end

      it 'does not return events of today' do
        ev3 = ICS::Event.new
        ev3.date = Date.today
        ev3.summary = 'foxymusic'
        ev3.id = 90_210
        ev3.calendar_id = 5
        calendar.load_events [ev1, ev2, ev3]
        actual = calendar.events
        expect(actual.length).to eq(2)
      end

      it 'sorts events from soonest to latest' do
        ev3 = ICS::Event.new
        ev3.date = Date.today + 15
        ev3.summary = 'foxymusic'
        ev3.id = 90_210
        ev3.calendar_id = 5
        calendar.load_events [ev3, ev2, ev1]
        actual = calendar.events
        expect(actual[0]).to eq ev2
        expect(actual[1]).to eq ev1
        expect(actual[2]).to eq ev3
      end

      it 'returns all events when count is -1' do
        calendar.load_events [ev1, ev2]
        actual = calendar.events(-1)
        expect(actual.length).to eq(2)
      end

      it 'returns all events when count is missing' do
        calendar.load_events [ev1, ev2]
        actual = calendar.events
        expect(actual.length).to eq(2)
      end

      it 'returns the specified number of events when count is present' do
        calendar.load_events [ev1, ev2]
        actual = calendar.events 2
        expect(actual.length).to eq(2)
        actual = calendar.events 1
        expect(actual.length).to eq(1)
        actual = calendar.events 0
        expect(actual.length).to eq(0)
      end

      it 'returns all events when count is exceeds number of events' do
        calendar.load_events [ev1, ev2]
        actual = calendar.events 10
        expect(actual.length).to eq(2)
      end
    end

    describe 'add_event' do
      it 'adds the given event to the calendar' do
        ev3 = ICS::Event.new
        ev3.date = Date.today + 1
        ev3.summary = 'foxymusic'
        ev3.id = 90_210
        ev3.calendar_id = 5
        calendar.load_events [ev1, ev2]
        actual = calendar.events
        expect(actual).not_to include ev3
        expect(actual.length).to eq(2)
        calendar.add_event ev3
        actual = calendar.events
        expect(actual).to include ev3
        expect(actual.length).to eq(3)
      end
    end

    describe 'getLeastRecentEven' do
      it 'returns the latest event' do
        ev3 = ICS::Event.new
        ev3.date = Date.today + 12
        ev3.summary = 'foxymusic'
        ev3.id = 90_210
        ev3.calendar_id = 5
        calendar.load_events [ev3, ev1, ev2]
        actual = calendar.least_recent_event
        expect(actual).to eq(ev3)
      end

      it 'returns nil when no events are stored in the calendar' do
        actual = calendar.least_recent_event
        expect(actual).to be_nil
      end
    end
  end
end
