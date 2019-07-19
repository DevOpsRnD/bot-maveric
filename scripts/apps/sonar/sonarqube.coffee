# Description:
#   A hubot script that displays stats from SonarQube.
#
# Dependencies:
#   N/A
#
# Configuration:
#   knife configured in your $PATH, you'll see a WARNING in console if you don't have it
#
# Commands:
#   hubot sonar set server <server> - Set address of SonarQube server
#   hubot sonar coverage <project name> - chef: Runs chef-client across an environment
#   hubot sonar issues <project name> -  chef: Lists all environments on chef server
#   hubot sonar bugs <project name>
# Author:
#   Peter Strapp <peter@strapp.co.uk>
#   Brian Antonelli <brian.antonelli@autotrader.com>


server = '35.177.142.47:9000'
headerAuthorization = "Basic YTU4NDVkMDJmMjhhNmFlY2E4Y2FhMjljZjRkMDYwMjkzMzUwZDMwMjo="

module.exports = (robot) ->
  robot.respond /sonar coverage (.*)/, (msg) ->
    findResource robot, msg, msg.match[1], (resourceName, robot, msg) ->
      coverage(resourceName, robot, msg)

  robot.respond /sonar issues (.*)/, (msg) ->
    findResource robot, msg, msg.match[1], (resourceName, robot, msg) ->
      violations(resourceName, robot, msg,"VULNERABILITY")
	
  robot.respond /sonar bugs (.*)/, (msg) ->
    findResource robot, msg, msg.match[1], (resourceName, robot, msg) ->
      violations(resourceName, robot, msg,"BUG")

  robot.respond /sonar set server (.*)/, (msg) ->
    server = msg.match[1].replace(/http:\/\//i, '')
    msg.send "Sonar server is set to: #{server}"

coverage = (resourceName, robot, msg) ->
  robot.http("http://35.177.142.47:9000/api/measures/search_history?metrics=coverage&component=#{resourceName}").get() (err, res, body) ->
    handleError(err, res.statusCode, msg)
    resource = JSON.parse(body)
    val = 0
    if typeof resource.measures isnt 'undefined' and typeof resource.measures[0] isnt 'undefined' and typeof resource.measures[0]["history"]
      if typeof resource.measures[0]["history"][resource.measures[0]["history"].length-1].value != 'undefined'
        val = resource.measures[0]["history"][resource.measures[0]["history"].length-1].value


    msg.send "Unit test coverage of project #{resourceName} is #{val} %."

violations = (resourceName, robot, msg,issueType) ->
  robot.http("http://#{server}/api/issues/search?componentKeys=#{resourceName}&types=#{issueType}&resolved=no").get() (err, res, body) ->
    handleError(err, res.statusCode, msg)

    resource = JSON.parse(body)
    #name = resource.name
    val = resource.total
    msg.send "The project #{resourceName} has #{val} issues."

findResource = (robot, msg, searchTerm, callback) ->
  robot.http("http://#{server}/api/projects/search").header("Authorization","#{headerAuthorization}").get() (err, res, body) ->
    handleError(err, res.statusCode, msg)
    body = JSON.parse(body)
    #if body.components[0] isnt 'undefined'
      #resourceName = body.components[0].key

    resourceName = resource.key for resource in body.components when resource.key.toLowerCase().indexOf(searchTerm.toLowerCase()) isnt -1

    console.log resourceName
    if typeof resourceName isnt 'undefined'
      callback(resourceName, robot, msg)
    else
      msg.send "Resource \"#{searchTerm}\" not found"

handleError = (err, statusCode, msg) ->
  if err
    msg.send "Encountered an error: #{err}"
    return

  if statusCode isnt 200
    msg.send "Request didn't come back HTTP 200."
    return
