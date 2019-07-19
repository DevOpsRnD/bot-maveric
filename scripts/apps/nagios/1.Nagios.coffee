# Description:
#   This script receives pages in the formats
#        /usr/bin/curl -d host="$HOSTALIAS$" -d output="$SERVICEOUTPUT$" -d description="$SERVICEDESC$" -d type=service -d notificationtype="$NOTIFICATIONTYPE$ -d state="$SERVICESTATE$" $CONTACTPAGER$
#        /usr/bin/curl -d host="$HOSTNAME$" -d output="$HOSTOUTPUT$" -d type=host -d notificationtype="$NOTIFICATIONTYPE$" -d state="$HOSTSTATE$" $CONTACTPAGER$
#
#   Example contact pager attribute is like the following:
#     http://<hubot_host>:8080/hubot/nagios/<room_name>
#
#   Based on a gist by bentwr (https://gist.github.com/benwtr/5691225) 
#   which is from a gist by oremj (https://gist.github.com/oremj/3702073)
#
# Configuration:
#   HUBOT_NAGIOS_AUTH - <username>:<password>
#   HUBOT_NAGIOS_URL  - https://nagios.example.com/nagios/cgi-bin
#   HUBOT_NAGIOS_NOTIFY_CHANNEL  - ########
#
# Commands:
#   hubot help - display the help text
#

Crypto = require 'crypto'

defaultRoom = process.env.HUBOT_NAGIOS_NOTIFY_CHANNEL

formatNotification = (title, data, cb) ->

  color = 'good'
  if data.notificationType == 'PROBLEM'
    color = 'danger'

  notification = {
    "attachments": [
      {
        "color": color,
        "pretext": title,
        "author_name": "Nagios",
        "text": "_#{data.message}_",
        "fields": [
          { "title": "Host", "value": data.host, "short": true },
          { "title": "Type", "value": data.notificationType, "short": true }
        ]
      }
    ]
  }

  if data.notificationFor == 'service'
    notification.attachments[0].fields.push({ "title": "Service", "value": data.service, "short": true })
    notification.attachments[0].fields.push({ "title": "Status", "value": data.status, "short": true })

  cb notification

module.exports = (robot) ->
  robot.router.post '/hubot/nagios/host', (request, response) ->

    notificationTitle = "Received a notification from Nagios"
    notificationData = {
      "host": request.body.host,
      "notificationType": request.body.notificationtype,
      "message": request.body.hostoutput,
      "notificationFor": 'host'
    }

    if defaultRoom
      formatNotification notificationTitle, notificationData, (notification) ->
        robot.messageRoom defaultRoom, notification

    robot.emit "nagios.notification.host", notificationData, defaultRoom

    response.end ""
  
  robot.router.post '/hubot/nagios/service', (request, response) ->

    notificationTitle = "Received a notification from Nagios"
    notificationData = {
      "host": request.body.host,
      "notificationType": request.body.notificationtype,
      "service": request.body.servicedescription,
      "status": request.body.servicestate,
      "message": request.body.serviceoutput,
      "notificationFor": 'service'
    }
    
    nagiosJob = "#{notificationData.host}:#{notificationData.service}"
    nagiosJobId = Crypto.createHash('md5').update(nagiosJob).digest('hex')
    room = robot.brain.get nagiosJobId

    if !room || room == ''
      room = defaultRoom
    else
      if notificationData.status == 'OK'
        robot.brain.remove nagiosJobId
    
    if room
      formatNotification notificationTitle, notificationData, (notification) ->
        robot.messageRoom room, notification
      
    robot.emit "nagios.notification.service", notificationData, room
    response.end ""
