module.exports = (robot) ->
 
  robot.router.post "/hubot/sonar/notification", (req, res,body) ->
      res_msg = "Failure"
      if typeof req.body.status isnt 'undefined' and req.body.status =="SUCCESS"
       res_msg = req.body.qualityGate.status
      else
       res_msg = "Error in retreiving result."
      
      #msg.send "SonarQube Quality Gate Status:- #{res_msg}"
      room = process.env.HUBOT_NAGIOS_NOTIFY_CHANNEL
      announceSonarHostMessage res_msg, (msg) ->
       robot.messageRoom room, msg
      res.end ""


announceSonarHostMessage = (res_msg,cb) ->
  cb "SonarQube Quality Gate Status :- *#{res_msg}*"  
