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

  def update_subscriber(_sub)
    raise NotImplementedError
  end

  def flush
    raise NotImplementedError
  end

  def calendars
    raise NotImplementedError
  end
end
