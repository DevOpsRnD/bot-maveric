# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

Slack = require "./slack"
SlackToHTML = require "./SlackToHTML"
LDAP = require "./ldap"

module.exports = (robot) ->


    ### objLdap = new LDAP robot
    objLdap.listRoleMembers process.env.HUBOT_NAGIOS_LDAP_TEAM_OU, (memberList) ->
        console.log "Members found"
        console.log memberList ###

        
    # Create channel once ticket is created in jira
    robot.on "jira.ticket.created", (details) ->
        objSlack = new Slack robot
        objSlack.createRoom details.ticket.key, (roomDetails) ->
            roomDetails = JSON.parse(roomDetails)
            
            if roomDetails.ok == true
                robot.messageRoom details.room, "Incedent has been reported. Please track the same under ##{roomDetails.channel.name}"

                objSlack.setPurpose roomDetails.channel.id, details.ticket.fields.summary, () ->

                objSlack.inviteMembers roomDetails.channel.id, process.env.HUBOT_SLACK_BOT_ID , () ->
                
                objLdap = new LDAP robot
                objLdap.listRoleMembers process.env.HUBOT_LDAP_DEV_TEAM_OU, (memberList) ->
                    if memberList.length
                        
                        slackUsers = robot.adapter.client.rtm.dataStore.users
                        
                        for index, member of memberList
                            result = (slackUsers[user] for user of slackUsers when slackUsers[user].profile.email is member.mail)
                            if result?.length is 1
                                objSlack.inviteMembers roomDetails.channel.id, result[0].id , () ->
                
                robot.messageRoom roomDetails.channel.id, {
                    text: "Ticket has been logged in Jira."
                    attachments: [
                        details.ticket.toAttachment yes
                        details.assignee
                        details.transition
                    ]
                }
                
                notificationData = details.fields.extra
                notificationData.channelId = roomDetails.channel.id
                robot.emit "maveric.initiate.autoheal", notificationData, roomDetails.channel.id
            else
                robot.messageRoom details.room, "Failed to create channel for this incedent."
  
    # Track ticket transition notification from Jira
    robot.on "JiraTicketTransitioned", (ticket, transition, context, includeAttachment = no) ->
        jiraTransitions = robot.jira.Config.maps.transitions
        lastTransition = jiraTransitions[jiraTransitions.length - 1]
        
        # Check whether ticket transitioned to last status
        if ticket.fields.status.name.toLowerCase() == lastTransition.jira.toLowerCase()
            objSlack = new Slack robot
            objSlack.searchRoomByName ticket.key, (roomDetails) ->
            
                if roomDetails
                    channelId = roomDetails.id
                    objSlack.getRoomHistory channelId, (roomHistory) ->

                        rawHistory = roomHistory
                        roomHistory = JSON.parse roomHistory
                        
                        historyExportPath = "#{process.env.HUBOT_SLACK_EXPORT_PATH}/history"
                        if roomHistory.ok
                            fs = require "fs"
                            filename = "#{historyExportPath}/#{roomDetails.name}_history.json"
                            fs.writeFile "#{filename}", rawHistory, (error) ->
                                
                                rawHistory = ''

                                if error
                                    console.error "Error writing file #{roomDetails.name}_history.json", error
                                    return
                                else
                                    objSlackExport = new SlackToHTML
                                    objSlackExport.export roomDetails.name, roomHistory, historyExportPath, (status) ->
                                        
                                        if !status
                                            console.error "Channel history export failed"
                                        else
                                            robot.messageRoom channelId, "History exported successfully."
                                            robot.emit "maveric.channelHistory.created", channelId, roomDetails.name, historyExportPath
                        else
                            console.error "Channel history not found"
                        

        