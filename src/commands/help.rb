# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'messages/message'

require 'i18n'

##
# This class represents the /help command
# given by the user.
class HelpCommand < Command
  def process(_msg, _userid, chatid)
    calendars = Container.get(:calendars)
    @message_sender.process(
      Message.new(
        i18nkey: 'help',
        i18nparams: {
          calendars_count: calendars.keys.length
        },
        id_recv: chatid,
        markup: nil
      )
    )
  end
end
