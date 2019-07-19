# Description:
#   Rundeck Events
#
# Configuration:
#
# Commands:
#
#
# Author:
#   Siddhesh K

Crypto = require 'crypto'

module.exports = (robot) ->

    robot.on "maveric.initiate.autoheal", (notificationData, room) ->
        console.log "maveric.initiate.autoheal"
        if notificationData.notificationType == 'PROBLEM'
            nagiosJob = "#{notificationData.host}:#{notificationData.service}"
            nagiosJobId = Crypto.createHash('md5').update(nagiosJob).digest('hex')
            if process.env.HUBOT_RUNDECK_NAGIOS_JOBS
                rundeckJobs = JSON.parse process.env.HUBOT_RUNDECK_NAGIOS_JOBS
                robot.brain.set rundeckJobs[nagiosJobId], notificationData.channelId
                robot.brain.set nagiosJobId, notificationData.channelId
                if rundeckJobs[nagiosJobId]
                    robot.messageRoom room, "Auto healing is initiated by Rundeck. Please wait to know the status"
                    robot.rundeck.runJob rundeckJobs[nagiosJobId], room, (resp) ->
                        if resp.error
                            robot.messageRoom room, "Error occured while autohealing issue. `#{resp.message}`"
                        
                else
                    console.log "Job id not found for this notification"

    robot.on "jenkins.build.success", (notificationData, room) ->
        if notificationData.buildStatus == 'FINALIZED'
            rundeckJobs = JSON.parse process.env.HUBOT_RUNDECK_NAGIOS_JOBS
            robot.rundeck.runJob rundeckJobs['JENKINS_BUILD_SUCCESS'], room, (resp) ->
                if resp.error
                    robot.messageRoom room, "Error occured build deployment. '`#{resp.message}`'"



                    

