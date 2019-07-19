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

# Will not run unless you have 'hubot-conversation' installed.
Conversation = require 'hubot-conversation'
Utils = require 'hubot-jira-bot/src/utils'
Ticket = require "hubot-jira-bot/src/jira/ticket"
fs = require "fs"
request = require 'request'

module.exports = (robot) ->

    # robot.respond "nagios.notification.service", (data, room) ->

    robot.on "nagios.notification.service", (notificationData, room) ->
        if notificationData.notificationType == 'PROBLEM'
            robot.messageRoom room, 'Incedent is getting reported, please wait...'
            keysArr = Object.keys(robot.jira.Config.maps.projects)
            projectKey = robot.jira.Config.maps.projects[keysArr[0]]
            fields = {
                description: "#{notificationData.message}\nHost: #{notificationData.host}\nservice: #{notificationData.service}\nType: #{notificationData.notificationType}\nStatus: #{notificationData.status}\n",
                extra: notificationData
            }
            robot.jira.Create.withRoom(projectKey, 'Task', notificationData.message, room, fields)
            .then (ticket) ->

    robot.on "maveric.channelHistory.created", (room, ticketKey, location) ->
        if ticketKey != ''
        
            options = {
                url: "#{robot.jira.Config.jira.url}/rest/api/2/issue/#{ticketKey}/attachments"
                formData: {
                    file: fs.createReadStream("#{location}/#{ticketKey}_history.html"),
                }
                headers: {
                    "X-Atlassian-Token": "no-check"
                    "Content-Type": "application/json"
                    "Authorization": 'Basic ' + new Buffer("#{robot.jira.Config.jira.username}:#{robot.jira.Config.jira.password}").toString('base64')
                }
            }
            
            request.post options, (err, httpResponse, body) ->
                if err
                    robot.messageRoom room, "Channel log failed to attach to `#{ticketKey}` ticket"
                    return console.error 'upload failed:', err
                
                robot.messageRoom room, "Channel log is successfully attached to `#{ticketKey}` ticket"

    
    robot.hear /New card (.*) added to list (.*) on board (.*)/i, (ticketData) ->
        messageData = ticketData.match[1]
        notificationFor = ticketData.match[2]
        ticketData = {
            "host": "localhost",
            "notificationType": "INFO",
            "service": "Service Description",
            "status": "STOPPED",
            "message": messageData,
            "notificationFor": notificationFor
        }

        fields = {
            description: "#{ticketData.message}\nHost: #{ticketData.host}\nservice: #{ticketData.service}\nType: #{ticketData.notificationType}\nStatus: #{ticketData.status}\n",
            extra: ticketData
        }

        keysArr = Object.keys(robot.jira.Config.maps.projects)
        projectKey = robot.jira.Config.maps.projects[keysArr[0]]
        room = 'web-app'
        robot.jira.Create.withRoom(projectKey, 'Task', ticketData.message, room, fields)
