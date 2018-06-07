# frozen_string_literal: true

require 'commands/command'

require 'i18n'

##
# This class represents a /start command
# given by the user.
class StartCommand < Command
  def process(_msg, _userid, chatid)
    bot = Container.get(:bot)
    @message_sender.process(
      I18n.t(
        'start',
        botname: bot.bot_instance.api.getMe['result']['username']
      ),
      chatid
    )
  end
end
