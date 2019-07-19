querystring = require 'querystring'
url = require 'url'

defaultRoom = process.env.HUBOT_NAGIOS_NOTIFY_CHANNEL

module.exports = (robot) ->
  robot.router.post '/hubot/rundeck_notification', (request, response) ->
    query = querystring.parse(url.parse(request.url).query)
    name = query.job
    executionId = query.execution_id
    jobId = query.job_id
    status = query.status
    room = if query.room then query.room else ''
    if !room || room == ''
      room = robot.brain.get jobId
      if !room || room == ''
        room = defaultRoom
      else
        if status != 'running'
          robot.brain.remove jobId

    announceJiraHostMessage name, executionId, status, (msg) ->
      robot.messageRoom room, msg
    response.end ""


announceJiraHostMessage = (name, executionId, status, cb) ->
  cb "Received a notification from RUNDECK \n Job Name ::*#{name}* \n Execution Id::  *#{executionId}* \n Job Status:: *#{status}*" 


