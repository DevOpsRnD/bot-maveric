
_ = require "underscore"

class Slack

    constructor: (@robot) ->

    createRoom: (channelName, cb) ->
        @robot.http("#{process.env.SLACK_API_URL}channels.create?token=#{process.env.SLACK_API_TOKEN}&name=#{channelName}")
            .header('accept', '*/*')
            .header('User-Agent', "Hubot/#{@version}")
            .header('Content-Type', 'text/plain')
            .get() (err, res, body) ->
                cb body
    
    setPurpose: (channelId, purpose, cb) ->
        @robot.http("#{process.env.SLACK_API_URL}channels.setPurpose?token=#{process.env.SLACK_API_TOKEN}&channel=#{channelId}&purpose=#{purpose}&pretty=1")
            .header('accept', '*/*')
            .header('User-Agent', "Hubot/#{@version}")
            .header('Content-Type', 'text/plain')
            .get() (err, res, body) ->
                cb body

    inviteMembers: (channelId, userId, cb) ->
        @robot.http("#{process.env.SLACK_API_URL}channels.invite?token=#{process.env.SLACK_API_TOKEN}&channel=#{channelId}&user=#{userId}&pretty=1")
        .header('accept', '*/*')
        .header('User-Agent', "Hubot/#{@version}")
        .header('Content-Type', 'text/plain')
        .get() (err, res, body) ->
            cb body

    getRoomList: (cb) ->
        @robot.http("#{process.env.SLACK_API_URL}channels.list?token=#{process.env.SLACK_API_TOKEN}&exclude_archived=true")
        .header('accept', '*/*')
        .header('User-Agent', "Hubot/#{@version}")
        .header('Content-Type', 'text/plain')
        .get() (err, res, body) ->
            cb body

    searchRoomByName: (roomName, cb) ->
        @getRoomList (roomList) ->
            roomList = JSON.parse roomList
            searchedRoom = false
            if roomList.ok == true && roomList.channels.length > 0
                for index, room of roomList.channels
                    if room.name.toLowerCase() == roomName.toLowerCase()
                        cb room
    
    getRoomHistory: (channelId, cb) ->
        @robot.http("#{process.env.SLACK_API_URL}channels.history?token=#{process.env.SLACK_API_TOKEN}&channel=#{channelId}&count=500")
        .header('accept', '*/*')
        .header('User-Agent', "Hubot/#{@version}")
        .header('Content-Type', 'text/plain')
        .get() (err, res, body) ->
            cb body
    
    historyExportToHtml: (history, cb) ->
        

module.exports = Slack
