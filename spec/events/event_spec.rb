
# frozen_string_literal: true

require 'events/event'

RSpec.describe Events::Event do
  describe 'date' do
    it 'returns the correct date' do
      e = described_class.new
      e.date = Date.today
      expect(e.date).to eq(Date.today)
    end

    it 'updates the date' do
      e = described_class.new
      e.date = Date.today
      e.date = Date.today - 1
      expect(e.date).to eq(Date.today - 1)
    end
  end

  describe 'summary' do
    it 'returns the correct summary' do
      e = described_class.new
      e.summary = 'foo'
      expect(e.summary).to eq('foo')
    end

    it 'updates the summary' do
      e = described_class.new
      e.summary = 'foo'
      e.summary = 'bar'
      expect(e.summary).to eq('bar')
    end
  end

  describe 'id' do
    it 'returns the correct id' do
      e = described_class.new
      e.id = 1
      expect(e.id).to eq(1)
    end

    it 'updates the id' do
      e = described_class.new
      e.id = 1
      e.id = 2
      expect(e.id).to eq(2)
    end
  end

  describe 'calendar_id' do
    it 'returns the correct calendar_id' do
      e = described_class.new
      e.calendar_id = 1
      expect(e.calendar_id).to eq(1)
    end

    it 'updates the calendar_id' do
      e = described_class.new
      e.calendar_id = 1
      e.calendar_id = 2
      expect(e.calendar_id).to eq(2)
    end
  end
end
