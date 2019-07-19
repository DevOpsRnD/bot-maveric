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

HUBOT_JENKINS_COLOR_ABORTED       = "warning"
HUBOT_JENKINS_COLOR_FAILURE       = "danger"
HUBOT_JENKINS_COLOR_FIXED         = "#d5f5dc"
HUBOT_JENKINS_COLOR_STILL_FAILING = "danger"
HUBOT_JENKINS_COLOR_SUCCESS       = "good"
HUBOT_JENKINS_COLOR_DEFAULT       = "#ffe094"

module.exports = (robot) ->
  robot.router.post "/hubot/jenkins/notification", (req, res) ->
    room = req.body.build.parameters.SlackID

    unless room?
      res.status(400).send("Bad Request").end()
      return

    if req.query.debug
      console.log req.body

    data = req.body

    res.status(202).end()

    return if data.build.phase == "COMPLETED"

    payload =
      message:
        room: "##{room}"
      content:
        fields: []

    payload.content.fields.push
      title: "Phase"
      value: data.build.phase
      short: true
    
    payload.content.fields.push
        title: "Build #"
        value: "<#{data.build.full_url}|#{data.build.number}>"
        short: true

    status = "#{data.build.phase}"

    switch data.build.phase
      when "FINALIZED"
        status = "*#{data.build.phase}* with *#{data.build.status}*"

        payload.content.fields.push
          title: "Status"
          value: data.build.status
          short: true

        color = switch data.build.status
          when "ABORTED"       then HUBOT_JENKINS_COLOR_ABORTED
          when "FAILURE"       then HUBOT_JENKINS_COLOR_FAILURE
          when "FIXED"         then HUBOT_JENKINS_COLOR_FIXED
          when "STILL FAILING" then HUBOT_JENKINS_COLOR_STILL_FAILING
          when "SUCCESS"       then HUBOT_JENKINS_COLOR_SUCCESS
          else                      HUBOT_JENKINS_COLOR_DEFAULT

        notificationData = []
        notificationData.buildStatus = data.build.phase

        robot.emit "jenkins.build.success", notificationData, room

      when "STARTED"
        status = data.build.phase
        color = "#e9f1ea"

        params = data.build.parameters

        if params and params.ghprbPullId
          payload.content.fields.push
            title: "Source branch"
            value: params.ghprbSourceBranch
            short: true
          payload.content.fields.push
            title: "Target branch"
            value: params.ghprbTargetBranch
            short: true
          payload.content.fields.push
            title: "Pull request"
            value: "#{params.ghprbPullId}: #{params.ghprbPullTitle}"
            short: true
          payload.content.fields.push
            title: "URL"
            value: params.ghprbPullLink
            short: true
        else if data.build.scm.commit
          payload.content.fields.push
            title: "Commit SHA1"
            value: data.build.scm.commit
            short: true
          payload.content.fields.push
            title: "Branch"
            value: data.build.scm.branch
            short: true

    payload.content.color    = color
    payload.content.pretext  = "Jenkins #{data.name} #{status} (<#{data.build.full_url}|View Details>)"
    payload.content.fallback = payload.content.pretext

    robot.messageRoom room, { "attachments": [ payload.content ] }
    # robot.emit "slack.attachment", payload