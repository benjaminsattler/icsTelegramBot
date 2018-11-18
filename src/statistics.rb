# frozen_string_literal: true

require 'date'
##
# This class collects various run time statistics
class Statistics
  @recvd_msgs_counter = 0
  @sent_msgs_counter = 0
  @sent_reminders = 0
  @start_timestamp = 0

  def initialize
    @recvd_msgs_counter = 0
    @sent_msgs_counter = 0
    @sent_reminders = 0
    @start_timestamp = Time.now
  end

  def recv_msg
    @recvd_msgs_counter += 1
    nil
  end

  def sent_msg
    @sent_msgs_counter += 1
    nil
  end

  def sent_reminder
    @sent_reminders += 1
  end

  def get
    {
      recvd_msgs_counter: @recvd_msgs_counter,
      sent_msgs_counter: @sent_msgs_counter,
      sent_reminders: @sent_reminders,
      starttime: @start_timestamp,
      uptime: Time.now - @start_timestamp
    }
  end
end
