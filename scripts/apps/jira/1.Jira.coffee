# Description:
#   Jira conversational flow
#
# Configuration:
#
# Commands:
#   jira menu
#
# Author:
#   Siddhesh K

Jira = require 'hubot-jira-bot/src/jira/index'
Config = require 'hubot-jira-bot/src/config'

Adapters = require "hubot-jira-bot/src/adapters"

module.exports = (robot) ->
    robot.jira = Jira
    robot.jira.Config = Config

    switch robot.adapterName
      when "slack"
        adapter = new Adapters.Slack robot
      else
        adapter = new Adapters.Generic robot

    send = (context, message, filter=yes) ->
        context = adapter.normalizeContext context
        message = filterAttachmentsForPreviousMentions context, message if filter
        adapter.send context, message

    filterAttachmentsForPreviousMentions = (context, message) ->
        return message if _(message).isString()
        return message unless message.attachments?.length > 0
        room = context.message.room

        removals = []
        for attachment in message.attachments when attachment and attachment.type is "JiraTicketAttachment"
            ticket = attachment.author_name?.trim().toUpperCase()
            continue unless Config.ticket.regex.test ticket

            key = "#{room}:#{ticket}"
            if Utils.cache.get key
                removals.push attachment
                Utils.Stats.increment "jirabot.surpress.attachment"
                @robot.logger.debug "Supressing ticket attachment for #{ticket} in #{@adapter.getRoomName context}"
            else
                Utils.cache.put key, true, Config.cache.mention.expiry

        message.attachments = _(message.attachments).difference removals
        return message

    robot.jira.utils = {
        send,
        filterAttachmentsForPreviousMentions
    }

    robot.respond /jira .*/i, (msg) ->
        console.log msg.message.user
        return
        if !Object.keys(robot.jira.Config.maps.projects).length
            msg.reply "Hi @#{msg.message.user.name}, I couldn't find project configured for Jira. Can you please do it?"
            msg.finish()
    
