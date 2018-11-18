# frozen_string_literal: true

require 'commands/command'
require 'container'
##
# This class represents the base class
# for any administration command.
class AdminCommand < Command
  def initialize(bot, command)
    @bot = bot
    @command = command
  end

  def process(msg, userid, chatid, silent)
    return unless @bot.admin_user?(chatid)

    @command.process(msg, userid, chatid, silent)
  end
end
