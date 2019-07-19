# Description:
#   Jenkins conversational flow
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_AUTH
#
#   Auth should be in the "user:password" format.
#
# Commands:
#   jenkins menu
#
# Author:
#   Siddhesh K

# Will not run unless you have 'hubot-conversation' installed.
Conversation = require 'hubot-conversation'

jobNotFound = (msg) ->
    msg.reply "I couldn't find that job. Try `jenkins menu` to get a list."

formatNotification = (jobName, jobDetails, cb) ->
  cb "*Update from Jenkins:*\nBuild Number: *<#{jobDetails.full_url}|##{jobDetails.number}>* \nJob name: *#{jobName}* \nPhase: *#{jobDetails.phase}* \tStatus: *#{jobDetails.status}*"

module.exports = (robot) ->

    findJob = (index) ->
        job = robot.jenkins.jobList[index]
        if job
            return job
        else
            return false
    
    ### robot.router.post '/hubot/jenkins/notification', (request, response) ->
        
        jobName = request.body.name
        room =  request.body.build.parameters.SlackID
        
        formatNotification jobName, request.body.build, (msg) ->
            robot.messageRoom room, msg
        response.end "" ###

    # Creating an instance of conversation. Set so only a particular user can reply if they launch the conversation.
    convo = new Conversation robot

    robot.respond /jenkins menu/i, (msg) ->
  
        msg.reply """
                    Hello! What would you like to do today? (Enter number):
                    [1] List projects
                    [2] Build project
                    [3] View project details
                    [4] Last build status
                """

        dialogOptions = convo.startDialog(msg)

        dialogOptions.addChoice /1/, (msg) ->
            robot.jenkins.list msg, robot

        dialogOptions.addChoice /2/, (msg) ->
            msg.reply 'Please choose project to build'
            robot.jenkins.list msg, robot

            dialogOptions.addChoice /(\d+)/i, (msg) ->
                job = findJob (parseInt(msg.match[0]) - 1)
                if job
                    msg.match[1] = job
                    robot.jenkins.build msg, true
                else
                    jobNotFound msg

        dialogOptions.addChoice /3/, (msg) ->
            msg.reply 'Please choose project to view details'
            robot.jenkins.list msg, robot

            dialogOptions.addChoice /(\d+)/i, (msg) ->
                job = findJob (parseInt(msg.match[0]) - 1)
                if job
                    msg.match[1] = job
                    robot.jenkins.describe msg
                else
                    jobNotFound msg

        dialogOptions.addChoice /4/, (msg) ->
            msg.reply 'Please choose project to get view last build status'
            robot.jenkins.list msg, robot

            dialogOptions.addChoice /(\d+)/i, (msg) ->
                job = findJob (parseInt(msg.match[0]) - 1)
                if job
                    msg.match[1] = job
                    robot.jenkins.last msg
                else
                    jobNotFound msg
