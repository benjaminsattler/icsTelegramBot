# frozen_string_literal: true

require 'statistics'
require 'time_difference'

RSpec.describe Statistics do
  describe 'recv_msg' do
    it 'increments the received messages counter by 1' do
      statistics = described_class.new
      old = statistics.get[:recvd_msgs_counter]
      statistics.recv_msg
      expect(statistics.get[:recvd_msgs_counter]).to equal(old + 1)
    end
  end

  describe 'sent_msg' do
    it 'increments to sent messages counter by 1' do
      statistics = described_class.new
      old = statistics.get[:sent_msgs_counter]
      statistics.sent_msg
      expect(statistics.get[:sent_msgs_counter]).to equal(old + 1)
    end
  end

  describe 'sent_reminder' do
    it 'increments to sent reminders counter by 1' do
      statistics = described_class.new
      old = statistics.get[:sent_reminders_counter]
      statistics.sent_reminder
      expect(statistics.get[:sent_reminders_counter]).to equal(old + 1)
    end
  end

  describe 'get' do
    it 'contains a fully populated object' do
      statistics = described_class.new
      actual = statistics.get
      expect(actual).to match(
        recvd_msgs_counter: an_instance_of(Integer),
        sent_msgs_counter: an_instance_of(Integer),
        sent_reminders_counter: an_instance_of(Integer),
        starttime: an_instance_of(Time),
        uptime: an_instance_of(TimeDifference)
      )
    end

    it 'returns 0 for all counters initially' do
      statistics = described_class.new
      actual = statistics.get
      expect(actual[:recvd_msgs_counter]).to equal(0)
      expect(actual[:sent_msgs_counter]).to equal(0)
      expect(actual[:sent_reminders_counter]).to equal(0)
    end
  end
end
