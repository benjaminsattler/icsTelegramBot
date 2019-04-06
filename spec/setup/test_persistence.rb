# frozen_string_literal: true

require 'persistence/persistence'

##
# This class will be used for tests against the
# telegram bot api.
class TestPersistence < Persistence
  def initialize
    @message_log = []
    @notification_log = []
  end

  def add_subscriber(_sub)
    raise NotImplementedError
  end

  def remove_subscriber(_sub)
    raise NotImplementedError
  end

  def subscriber_by_id(_id)
    raise NotImplementedError
  end

  def subscriptions_for_id(_id)
    raise NotImplementedError
  end

  def all_subscribers(_eventlist)
    raise NotImplementedError
  end

  def update_time(_sub_id, _eventlist_id, _time)
    raise NotImplementedError
  end

  def update_day(_sub_id, _eventlist_id, _day)
    raise NotImplemenedError
  end

  def add_calendar(_calendar)
    raise NotImplementedError
  end

  def calendars
    raise NotImplementedError
  end

  def add_to_message_log(message)
    @message_log.push(message)
  end

  def message_from_log(_message_id)
    raise NotImplementedError
  end

  def add_to_notification_log(notification, timestamp)
    @notification_log.push(
      notification: notification,
      timestamp: timestamp
    )
  end

  def logged_messages
    @message_log
  end

  def logged_notifications
    @notification_log
  end
end
