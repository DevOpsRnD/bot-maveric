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
moment = require 'moment'

objectToChoice = (choiceObject) ->
    optionsStr = ''
    optionsArr = []
    for key, type of choiceObject
        optionsArr.push type
        optionsStr += "[#{optionsArr.length}] #{type}\n"

    regex = new RegExp "[0-#{optionsArr.length}]"
    return [optionsArr, optionsStr, regex]


module.exports = (robot) ->

    convo = new Conversation robot

    robot.respond /jira menu/i, (msg) ->
        chooseProject msg, (projectKey) ->
            menuOptions msg, projectKey

    robot.respond /jira stats/i, (msg) ->
        chooseProject msg, (projectKey) ->
            msg.reply "_Let me check and get back with the jira statistics_"

            jql = "project = '#{projectKey}'"
            jql += "  "
            Utils.fetch "#{robot.jira.Config.jira.url}/rest/api/2/search", {
                method: "POST"
                body: JSON.stringify {
                    jql: jql
                    startAt: 0
                    maxResults: 1000
                    fields: [ "status", "created" ]
                }
            }
            .then (resp) ->
                statsArr = []
                reportArr = []
                if resp.total > 0
                    
                    reportFilters = [
                        { title: 'Last 1 day', date: moment().subtract(1, 'day').format() },
                        { title: 'Last 1 week', date: moment().subtract(1, 'week').format() },
                        { title: 'Last 2 Week', date: moment().subtract(2, 'weeks').format() },
                        { title: 'Last 1 month', date: moment().subtract(1, 'month').format() }
                    ]
                    
                    for index, issue of resp.issues
                        if !statsArr[issue.fields.status.name]
                            statsArr[issue.fields.status.name] = 1
                        else
                            statsArr[issue.fields.status.name]++
                        
                        for index, report of reportFilters
                            if moment(issue.fields.created).isAfter(report.date)
                                if !reportArr[report.title]
                                    reportArr[report.title] = 1
                                else
                                    reportArr[report.title]++

                    attachement = {
                        pretext: "_Please find below statistics_"
                        author_name: "Jira"
                    }
                    attachement.fields = []
                    for statusType, count of statsArr
                        attachement.fields.push {
                            title: statusType + " : `#{count}`"
                            value: ''
                            short: true
                        }
                    attachement.fields.push {
                        title: '------------------------'
                        value: ''
                        short: false
                    }
                    for title, count of reportArr
                        attachement.fields.push {
                            title: title + " : `#{count}`"
                            value: ''
                            short: true
                        }
                    attachement.fields.push {
                        title: '------------------------'
                        value: ''
                        short: false
                    }
                    attachement.fields.push {
                        title: "Total Issues : `#{resp.total}`"
                        value: ''
                        short: false
                    }
                    msg.send { attachments: [ attachement ] }
                    
    
    robot.respond /jira report/i, (msg) ->
        chooseProject msg, (projectKey) ->
            msg.reply "_Let me send you report_"

            jql = "project = '#{projectKey}'"
            jql += " AND key = 'JIR-3'  "
            Utils.fetch "#{robot.jira.Config.jira.url}/rest/api/2/search", {
                method: "POST"
                body: JSON.stringify {
                    jql: jql
                    startAt: 0
                    maxResults: 1
                }
            }
            .then (resp) ->
                statsArr = []
                reportArr = []
                console.log resp
                console.log resp.issues[0].fields
                if resp.total > 0
                    csvData = [
                        'Type',
                        'Key',
                        'Summary',
                        'Assignee',
                        'Reporter',
                        'Priority',
                        'Status',
                        'Created',
                        'Updated'
                    ]
                    csvData = []
                    for index, record of resp.issues
                        csvData.push([
                            record.fields.issuetype.name,
                            record.key,
                            record.fields.summary,
                            record.key,
                            record.fields.reporter.displayName,
                            record.fields.priority.name,
                            record.fields.status.name,
                            record.fields.created,
                            record.fields.updated
                        ])

    chooseProject = (msg, cb) ->
        # Auto select project in case single project is configured, else show list of projects
        if Object.keys(robot.jira.Config.maps.projects).length == 1
            keysArr = Object.keys(robot.jira.Config.maps.projects)
            projectKey = robot.jira.Config.maps.projects[keysArr[0]]
            msg.reply "_Auto selected project : `#{projectKey}`_"
            cb projectKey
        else
            optionDetails = objectToChoice robot.jira.Config.maps.projects
            
            msg.reply """
                _Please choose project:_
                #{optionDetails[1]}
            """

            chooseProjectDialog = convo.startDialog(msg)

            chooseProjectDialog.addChoice optionDetails[2], (msg) ->
                projectKey = optionDetails[0][parseInt(msg.match[0]) - 1]
                cb projectKey

    # List operations that can be performed in jira
    menuOptions = (msg, projectKey) ->
        if projectKey.length != ''
            msg.reply """
                        _Hello! What would you like to do today? (Enter number):_
                        [1] Select Ticket
                        [2] Create Ticket
                        [3] Search Ticket
                        [4] List tickets assigned to me
                    """
            
            dialogOptions = convo.startDialog(msg)
            
            dialogOptions.addChoice /1/, (msg) ->
                selectTicketOptions msg, projectKey

            dialogOptions.addChoice /2/, (msg) ->
                createTicketOptions msg, projectKey
            
            dialogOptions.addChoice /3/, (msg) ->
                searchTicketOptions msg, projectKey
            
            dialogOptions.addChoice /4/, (msg) ->
                console.log "_No result found_"

    # List operations that can be performed on given ticket
    selectTicketOptions = (msg, projectKey) ->
        msg.reply "_Please enter ticket number:_"

        selectTicketDialog = convo.startDialog(msg)

        selectTicketDialog.addChoice /(\d+)/, (msg) ->
            ticketKey = "#{projectKey}-#{msg.match[0]}"
            jql = "project = '#{projectKey}'"
            jql += " and key = '#{ticketKey}'"
            Utils.fetch "#{robot.jira.Config.jira.url}/rest/api/2/search",
                method: "POST"
                body: JSON.stringify
                    jql: jql
                    startAt: 0
                    maxResults: 1
                    fields: robot.jira.Config.jira.fields
            .then (json) ->
                if json.issues.length > 0
                    ticket = new Ticket json.issues[0]
                    attachments = [ticket.toAttachment()]
                    
                    robot.jira.utils.send msg,
                        text: "_Selected ticket is : `#{ticketKey}`_"
                        attachments: attachments
                    , no

                    robot.jira.utils.send msg,
                        text: """
                            _What would you like to do with `#{ticketKey}`? (Enter number):_
                            [1] `Move` Ticket
                            [2] `Assign` Ticket
                            [3] `Comment` on Ticket
                            [4] Set `Priority`
                        """
                    , no
                    
                    # Move ticket
                    selectTicketDialog.addChoice /1/, (msg) ->

                        nextTransitions = []
                        statusFound = false
                        for key, transition of robot.jira.Config.maps.transitions
                            if statusFound
                                nextTransitions.push transition.jira
                            statusFound = true if ticket.fields.status.name.toLowerCase() == transition.jira.toLowerCase()

                        optionDetails = objectToChoice nextTransitions
                        
                        msg.reply """
                            _Please choose next ticket status:_
                            #{optionDetails[1]}
                        """
                        
                        # Set next ticket transition status
                        selectTicketDialog.addChoice optionDetails[2], (msg) ->
                            selectedIndex = parseInt(msg.match[0], 10) - 1
                            if nextTransitions[selectedIndex]
                                nextStatus = nextTransitions[selectedIndex]
                                nextStatus = (robot.jira.Config.maps.transitions).find (type) -> type.jira is nextStatus
                                robot.jira.Transition.forTicketKeyToState ticketKey, nextStatus.name, msg
                            else
                                msg.regex "_Invalid status"
                            
                    # Assign ticket
                    selectTicketDialog.addChoice /2/, (msg) ->
                        msg.reply """_Enter the name of person:_"""
                        
                        # Set next ticket transition status
                        regex = new RegExp "(?:#{robot.name} )?(?:@)?(.+)"
                        selectTicketDialog.addChoice regex, (msg) ->
                            console.log msg.match
                            robot.jira.Assign.forTicketKeyToPerson ticketKey, msg.match[1], msg

                else
                    msg.reply "_Ticket not found. Please try again._"
            

    # Create new ticket
    createTicketOptions = (msg, projectKey) ->
        ticketObj = {}

        if projectKey.length != ''
        
            ticketObj.project = projectKey
            
            msg.reply '_Please enter ticket name:_'

            createTicketDialog = convo.startDialog(msg)

            # Ticket subject
            regex = new RegExp "(?:#{robot.name} )?(.+)"
            createTicketDialog.addChoice regex, (msg) ->
                if msg.match[0] != 'cancel'
                    ticketObj.summary = msg.match[1]

                    optionDetails = objectToChoice robot.jira.Config.maps.types
                    
                    msg.reply """
                        _Please choose ticket type:_
                        #{optionDetails[1]}
                    """

                    # Ticket type list from configured list
                    createTicketDialog.addChoice optionDetails[2], (msg) ->
                        ticketObj.ticketType = optionDetails[0][parseInt(msg.match[0], 10) - 1]
                        
                        msg.reply """
                            _Enter description for this `#{ticketObj.ticketType}`:_
                        """

                        # Ticket description in case required
                        regex = new RegExp "(?:#{robot.name} )?(.+)"
                        createTicketDialog.addChoice regex, (msg) ->
                            fields = { description: msg.match[1] }
                            robot.jira.Create.with ticketObj.project, ticketObj.ticketType, ticketObj.summary, msg, fields

                else
                    return
    
    # Search ticket based on given keywords
    searchTicketOptions = (msg, projectKey) ->
        msg.reply "_Please enter string to search:_"
        
        searchTicketDialog = convo.startDialog(msg)

        regex = new RegExp "(?:#{robot.name} )?(.+)"
        searchTicketDialog.addChoice regex, (msg) ->
            searchStr = msg.match[1]
            robot.jira.Search.withQueryForProject(searchStr, '', msg)
            .then (results) =>
                attachments = (ticket.toAttachment() for ticket in results.tickets)
                robot.jira.utils.send msg,
                    text: results.text
                    attachments: attachments
                , no
            .catch (error) =>
                robot.jira.utils.send msg, "_Unable to search for `#{searchStr}` :sadpanda:_"
                robot.logger.error error.stack
