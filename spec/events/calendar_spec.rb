# frozen_string_literal: true

require 'events/calendar'
require 'events/event'

RSpec.describe Events::Calendar do
  let(:calendar) { described_class.new }
  let(:ev1) do
    e = Events::Event.new
    e.date = Date.today + 10
    e.summary = 'foobar'
    e.id = 42
    e.calendar_id = 1
    e
  end
  let(:ev2) do
    e = Events::Event.new
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
      expect(actual[0]).to be_instance_of Events::Event
      expect(actual[1]).to be_instance_of Events::Event
    end

    it 'does not return past events' do
      ev3 = Events::Event.new
      ev3.date = Date.today(-1)
      ev3.summary = 'foxymusic'
      ev3.id = 90_210
      ev3.calendar_id = 5
      calendar.load_events [ev1, ev2, ev3]
      actual = calendar.events
      expect(actual.length).to eq(2)
    end

    it 'does not return events of today' do
      ev3 = Events::Event.new
      ev3.date = Date.today
      ev3.summary = 'foxymusic'
      ev3.id = 90_210
      ev3.calendar_id = 5
      calendar.load_events [ev1, ev2, ev3]
      actual = calendar.events
      expect(actual.length).to eq(2)
    end

    it 'sorts events from soonest to latest' do
      ev3 = Events::Event.new
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
      ev3 = Events::Event.new
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
      ev3 = Events::Event.new
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
