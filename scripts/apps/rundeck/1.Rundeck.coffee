
class Rundeck

    constructor: (@robot) ->

    runJob: (jobId, room, cb) ->
        @robot.http("#{process.env.HUBOT_RUNDECK_URL}/api/21/job/#{jobId}/run?format=json")
        .header('User-Agent', "Hubot")
        .header('Content-Type', 'application/json')
        .header('X-Rundeck-Auth-Token', process.env.HUBOT_RUNDECK_TOKEN)
        .post() (err, res, body) ->
            if err?
                @robot.logger.error JSON.stringify(err)
            else
                cb JSON.parse body

module.exports = (robot) ->
    robot.rundeck = new Rundeck robot
