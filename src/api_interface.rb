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
end
