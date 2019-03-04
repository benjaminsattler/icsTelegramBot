# frozen_string_literal: true

# This interface abstracts concrete Persistence implementations
# and must be implemented by all persistence layers.
class Persistence
  def initialize; end

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

  def add_to_message_log(_message)
    raise NotImplementedError
  end

  def add_to_notification_log(_notification, _timestamp)
    raise NotImplementedError
  end
end
