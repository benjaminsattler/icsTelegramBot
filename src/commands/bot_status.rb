# frozen_string_literal: true

require 'commands/command'
require 'container'

require 'i18n'

##
# This class represents a /botstatus command
# given by the user.
class BotStatusCommand < Command
  def initialize(message_sender, sys_info)
    super(message_sender)
    @sys_info = sys_info
  end

  def process(_msg, _userid, chatid, silent = false)
    calendars = Container.get(:calendars)
    data_store = Container.get(:dataStore)
    bot = Container.get(:bot)
    statistics = bot.statistics.get
    docker_info = @sys_info.docker_info
    os_info = @sys_info.os_info
    text = []
    text << I18n.t(
      'botstatus.intro',
      uptime: statistics[:starttime].strftime('%d.%m.%Y %H:%M:%S'),
      calendar_count: calendars.keys.length
    )
    text << ''
    calendars.each_pair do |calendar_id, calendar|
      events_count = calendar[:eventlist].events.length
      subscribers_count = data_store.all_subscribers(calendar_id).length
      text << I18n.t(
        'botstatus.calendar_info',
        calendar_id: calendar_id,
        calendar_name: calendar[:description],
        event_count: events_count,
        subscribers_count: subscribers_count
      )
    end
    text << ''
    text << I18n.t(
      'botstatus.bot_info',
      bot_sent_msgs: statistics[:sent_msgs_counter],
      bot_recvd_msgs: statistics[:recvd_msgs_counter],
      bot_sent_reminders: statistics[:sent_reminders],
      bot_uptime: statistics[:uptime]
    )
    text << ''
    text << I18n.t(
      'botstatus.docker_info',
      docker_image_version: docker_info[:image_version],
      docker_image_author: docker_info[:image_author],
      docker_image_build_time: docker_info[:image_build_time],
      docker_image_source_url: docker_info[:image_source_url]
    )
    text << ''
    text << I18n.t(
      'botstatus.os_info',
      os_public_ip: os_info[:ip],
      os_uptime: os_info[:uptime],
      os_version: os_info[:version]
    )
    @message_sender.process(text.join("\n"), chatid, nil, silent)
  end
end
