# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md

# Import the Slack Developer Kit

{ WebClient } = require '@slack/web-api'

module.exports = (robot) ->
  
  if robot.adapterName == 'slack'
    web = new WebClient robot.adapter.options.token
    
    ### robot.react (res) ->
      # res.message is a ReactionMessage instance that represents the reaction Hubot just heard
      if res.message.type == "added" and res.message.item.type == "message"
        web.reactions.add
          name: res.message.reaction,
          channel: res.message.item.channel,
          timestamp: res.message.item.ts ###

    robot.hear /your boss/i, (res) ->
      res.send robot.adapterName
