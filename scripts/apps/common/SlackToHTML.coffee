moment = require 'moment'

class SlackToHTML

    constructor: () ->

    export: (channelName, history, location, cb) ->
        htmlOutput = ''
        if history.messages.length
            slackUsers = robot.adapter.client.rtm.dataStore.users

            stylesheet = @getStylesheet()
            messageBody = ''
            
            for index, message of history.messages

                ts = message.ts.split "."
                msgDateTime = moment.unix(ts[0]).format('ddd MMM gggg HH:mm:ss z')

                attachmentStr = ''
                if message.attachments
                    attachmentStr = JSON.stringify message.attachments

                userId = ''
                if message.user
                    userId = message.user
                else if message.bot_id
                    userId = message.bot_id
                
                memberInfo = (slackUsers[user] for user of slackUsers when slackUsers[user].id is userId)

                regexMemberMatch = /<@([a-z0-9]+)>/i
                mentionedMembers = message.text.match(regexMemberMatch)
                if mentionedMembers
                    # for index, memberData of mentionedMembers
                    memberId = mentionedMembers[1]
                    userInfo = (slackUsers[user] for user of slackUsers when slackUsers[user].id is memberId)

                    if userInfo.length > 0
                        message.text = message.text.replace(new RegExp("<@#{memberId}>", 'g'), "@" + userInfo[0].real_name)
                        attachmentStr = attachmentStr.replace(new RegExp("<@#{memberId}>", 'g'), "@" + userInfo[0].real_name)
                
                ### regexChannelMatch = /<#([a-z0-9]+)\|(.+)>/i
                mentionedChannels = message.text.match(regexChannelMatch)
                for index, channelInfo of mentionedChannels
                    userInfo = (slackUsers[user] for user of slackUsers when slackUsers[user].id is memberId)
                    if userInfo.length > 0
                        message.text.replace("<@#{memberId}>", userInfo[0].real_name)
                        attachmentStr.replace("<@#{memberId}>", userInfo[0].real_name) ###

                if memberInfo.length > 0
                    memberInfo = memberInfo[0]
                messageBody += """
                    <div>
                        <img src="#{memberInfo.profile.image_72}" />
                        <div class="message">
                            <div class="username">#{memberInfo.real_name}</div>
                            <div class="time">#{msgDateTime}</div>
                            <div class="msg">#{message.text}<br/>#{attachmentStr}</div>
                        </div>
                    </div>
                """
            htmlOutput = """
                <html>
                    <head>
                        <title>#{channelName} - History</title>
                        <style>#{stylesheet}</style>
                    </head>
                    <body>
                        <div class="messages">
                            #{messageBody}
                        </div>
                    </body>
            """
            
            fs = require "fs"
            filename = "#{location}/#{channelName}_history.html"
            fs.writeFile "#{filename}", htmlOutput, (error) ->
                cb false if error
                cb true
                
    getStylesheet: () ->
        stylesheet = """
			* {
				font-family:sans-serif;
			}
			body {
				text-align:center;
				padding:1em;
			}
			.messages {
				width:100%;
				max-width:700px;
				text-align:left;
				display:inline-block;
			}
			.messages > div {
                border-bottom: solid 1px #CCC;
                margin-bottom: 10px;
            }
			.messages img {
				background-color:rgb(248,244,240);
				width:36px;
				height:36px;
				border-radius:0.2em;
				display:inline-block;
				vertical-align:top;
				margin-right:0.65em;
                float: left;
			}
			.messages .time {
				display:inline-block;
				color:rgb(200,200,200);
				margin-left:0.5em;
                font-size: 12px;
			}
			.messages .username {
				display:inline-block;
				font-weight:600;
				line-height:1;
			}
			.messages .message {
				display:inline-block;
				vertical-align:top;
				line-height:1;
				width:calc(100% - 3em);
			}
			.messages .message .msg {
				line-height:1.5;
			}
		"""
        
module.exports = SlackToHTML