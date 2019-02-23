# frozen_string_literal: true

##
# This interface serves as the base for implementations
# of the Telegram bot api as specified at
# https://core.telegram.org/bots/api
class ApiInterface
  def send_message(_params)
    raise NotImplementedError
  end

  def send_document(_params)
    raise NotImplementedError
  end

  def get_file(_params)
    raise NotImplementedError
  end

  def listen
    raise NotImplementedError
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_me
    raise NotImplementedError
  end
  # rubocop:enable Naming/AccessorMethodName

  def self.run
    raise NotImplementedError
  end
end
