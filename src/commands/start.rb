# frozen_string_literal: true

require 'commands/command'
require 'i18n'
require 'messages/message'

##
# This class represents a /start command
# given by the user.
class StartCommand < Command
  def process(_msg, _userid, chatid)
    bot = Container.get(:bot)
    @message_sender.process(
      Message.new(
        i18nkey: 'start',
        i18nparams: {
          botname: bot.bot_instance.get_identity['result']['username']
        },
        id_recv: chatid,
        markup: nil
      )
    )
  end
end
