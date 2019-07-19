# Description:
#   Tool to help you manage your Trello boards from Slack. Conversation method, requires you to navigate through menus.
#
# Dependencies:
#   "node-trello": "latest"
#   "hubot-conversation": https://github.com/Imarkus/hubot-conversation
#
# Configuration:
#   HUBOT_TRELLO_KEY - Application key to access the Trello API methods
#   HUBOT_TRELLO_TOKEN - Token to connect you to bot user in Trello
#   HUBOT_SLACK_TOKEN - Token to connect you to bot user in Slack
#
# Commands:
#   Trello: Menu - Trello Methods
#
# Author:
#   jared barboza <jared.m.barboza@gmail.com>
#   Modifications and Additional Scripts by Angela Lukic (Mastek Ltd) <angela.lukic@mastek.com> or <angelalukic@live.co.uk> 

# Will not run unless you have 'node-trello' installed.
Trello = require 'node-trello'

# Creating an instance of Trello. This will automatically check that a Trello Key & Token have been provided
trello = new Trello process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN

# Will not run unless you have 'hubot-conversation' installed.
Conversation = require 'hubot-conversation'

boards = {}
lists = {}
cards = {}
checklists = {}
checkitems = {}

module.exports = (robot) ->
	
  # Creating an instance of conversation. Set so only a particular user can reply if they launch the conversation.
  convo = new Conversation robot

  robot.hear /trello menu/i, (msg) ->
    
    dialogLaunch = convo.startDialog(msg)
    
    msg.reply 'Hello! What would you like to do today? (Copy & Paste the Board ID):'
    trello.get '1/members/me', {boards: 'open', fields: 'username', board_fields: 'shortLink,name,shortUrl'}, (err,data) ->
      throw err if err
      for board in data.boards
        boards[board.shortLink] = board
        msg.send ' `' + board.shortLink + '` <' + board.shortUrl + '|' + board.name + '>'
      if data.boards.length is 0
        msg.send 'There do not appear to be any boards.'
        shutdown msg
      if data.boards.length is 1
        msg.send 'Automatically navigating to sole board.'
        for board in data.boards
          selectBoardOptions msg, board.shortLink
      dialogLaunch.addChoice /([a-zA-Z0-9]{8})/m, (msg) ->
        for board in data.boards
          if msg.match[1] is board.shortLink 
            selectBoardOptions msg, msg.match[1]
			
  selectBoardOptions = (msg, board_id) ->
    
    msg.reply 'What would you like me to do with [' + board_id + ']? (Please Select a Number)'
    msg.send " 1. Select List"
    msg.send " 2. Create New List"
    msg.send " 3. Archive Board"
    msg.send " 4. Select from Cards on Board"
    msg.send " 5. Select from Checklists on Board"
    msg.send " 6. Shutdown"

    dialogBoardOptions = convo.startDialog(msg)
	
    dialogBoardOptions.addChoice /1/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the List you wish me to go to:'
      trello.get '/1/boards/' + board_id, {lists: 'open', fields: 'name', list_fields:'name'}, (err,data) ->
        throw err if err
        for list in data.lists
          lists[list.id] = list
          msg.send ' `' + list.id + '` - ' + list.name
        if data.lists.length is 0
          msg.send 'There do not appear to be any lists in this board.'
          selectBoardOptions msg, board_id
        if data.lists.length is 1
          msg.send 'Automatically navigating to sole list.'
          for list in data.lists
            selectListOptions msg, board_id, list.id
        dialogBoardOptions.addChoice /([a-zA-Z0-9]{24})/m, (msg) ->
          for list in data.lists
            if msg.match[1] is list.id
              selectListOptions msg, board_id, msg.match[1]
		
    dialogBoardOptions.addChoice /2/, (msg) ->
      msg.reply 'What would you like to name this List?'
      dialogBoardOptions.addChoice /(.*)/, (msg) ->
        trello.post "/1/boards/#{board_id}/lists", {name: msg.match[1]}, (err,data) ->
          throw err if err
          console.log "List has been successfully created."
          shutdown msg
		
    dialogBoardOptions.addChoice /3/, (msg) ->
      trello.put "/1/boards/#{board_id}/closed", {value: true}, (err, data) ->
        throw err if err
        console.log "Board has been succesfully archived."
        shutdown msg
		
    dialogBoardOptions.addChoice /4/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the Card you wish me to go to:'
      trello.get "/1/boards/#{board_id}",{cards: 'visible', fields: 'name', card_fields: 'shortLink,name,shortUrl,idList'} , (err,data) ->
        throw err if err
        for card in data.cards
          cards[card.shortLink] = card
          msg.send ' `' + card.shortLink + '` ' + card.name + ' - ' + card.shortUrl
        dialogBoardOptions.addChoice /([a-zA-Z0-9]{8})/m, (msg) ->
          for card in data.cards
            if msg.match[1] is card.shortLink
              selectCardOptions msg, board_id, card.idList, msg.match[1]

    dialogBoardOptions.addChoice /5/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the Checklist you wish me to go to:'
      msg.send "Note: You cannot update a checkItem through this as the Trello API doesn't store List IDs in Checklists."
      trello.get "/1/boards/#{board_id}", {checklists: 'all', fields: 'name', checklist_fields: 'name, idCard'}, (err,data) ->
        throw err if err
        for checklist in data.checklists
          checklists[checklist.id] = checklist
          msg.send " `#{checklist.id}` - #{checklist.name}" 
        dialogBoardOptions.addChoice /([a-zA-Z0-9]{24})/m, (msg) ->
          for checklist in data.checklists
            if msg.match[1] is checklist.id
              selectCheckListOptions msg, board_id, null, checklist.idCard, msg.match[1]

    dialogBoardOptions.addChoice /6/, (msg) ->
      shutdown msg
	
  selectListOptions = (msg, board_id, list_id) ->
    msg.reply 'What would you like me to do with this List? (Please Select a Number):'
    msg.send " 1. Select Card"
    msg.send " 2. Create New Card"
    msg.send " 3. Archive List"
    msg.send " 4. Shutdown"
	
    dialogListOptions = convo.startDialog(msg)
	
    dialogListOptions.addChoice /1/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the Card you wish me to go to:'
      trello.get '/1/lists/' + list_id, {cards: 'open', fields: 'name', card_fields: 'shortLink,name,shortUrl'}, (err,data) ->
        throw err if err
        for card in data.cards
          cards[card.id] = card
          msg.send ' `' + card.shortLink + '` ' + card.name + ' - ' + card.shortUrl
        if data.cards.length is 0
          msg.send 'There do not appear to be any cards in this list.'
          selectListOptions msg, board_id, list_id
        if data.cards.length is 1
          msg.send 'Automatically navigating to sole card.'
          for card in data.cards
            selectCardOptions msg, board_id, list_id, card.shortLink
        dialogListOptions.addChoice /([a-zA-Z0-9]{8})/m, (msg) ->
          for card in data.cards
            if msg.match[1] is card.shortLink
              selectCardOptions msg, board_id, list_id, msg.match[1]
		
    dialogListOptions.addChoice /2/, (msg) ->
      msg.reply 'What would you like to name this Card?'
      dialogListOptions.addChoice /(.*)/, (msg) ->
        trello.post "/1/cards", {name: msg.match[1], idList: list_id}, (err, data) ->
          throw err if err
          console.log "Card successfully created: #{data.url}"
          shutdown msg
		
    dialogListOptions.addChoice /3/, (msg) ->
      trello.put "/1/lists/#{list_id}/closed", {value: true}, (err, data) ->
        throw err if err
        console.log "List has been succesfully archived."
        shutdown msg
		
    dialogListOptions.addChoice /4/, (msg) ->
      shutdown msg    
		
  selectCardOptions = (msg, board_id, list_id, card_id) ->
    msg.reply 'What would you like me to do with [' + card_id + ']? (Please Select a Number):'
    msg.send " 1. Move Card"
    msg.send " 2. Add Comment"
    msg.send " 3. Update Description"
    msg.send " 4. Assign Date"
    msg.send " 5. Get Attachments"
    msg.send " 6. Upload Attachment"
    msg.send " 7. Archive Card"
    msg.send " 8. View Checklists"
    msg.send " 9. Create New Checklist"
    msg.send " 0. Shutdown"
	
    dialogCardOptions = convo.startDialog(msg)
	
    dialogCardOptions.addChoice /1/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the List you wish to move this Card to:'
      trello.get '/1/boards/' + board_id, { lists: 'open', fields: 'name', list_fields: 'name' }, ( err, data ) ->
        throw err if err
        for list in data.lists
          lists[list.id] = list
          msg.send ' `' + list.id + '` - ' + list.name
         dialogCardOptions.addChoice /([a-zA-Z0-9]{24})/m, (msg) ->
          for list in data.lists
            if msg.match[1] is list.id
              trello.put '/1/cards/' + card_id + '/idList', {value: msg.match[1]}, (err, data) ->
               throw err if err
               console.log 'Card `' + card_id + '` has successfully been moved to `' + msg.match[1] + '`'
               shutdown msg
	
    dialogCardOptions.addChoice /2/, (msg) ->
      msg.reply 'What do you wish to say on this card?:'
      dialogCardOptions.addChoice /(.*)/, (msg) ->
        trello.post "/1/cards/#{card_id}/actions/comments", { text: msg.message.user.name + " commented via Slack: " + msg.match[1] }, ( err, data ) ->
          throw err if err
          console.log "Your comment has been added successfully to card `#{card_id}`."
          shutdown msg
		
    dialogCardOptions.addChoice /3/, (msg) -> 
      msg.reply 'What do you want the description to be?:'
      dialogCardOptions.addChoice /(.*)/, (msg) ->
        trello.put "/1/cards/#{card_id}/desc", {value: msg.match[1]}, (err, data) ->
          throw err if err
          console.log "Your description has been added successfully to card `#{card_id}`."
          shutdown msg
	
    dialogCardOptions.addChoice /4/, (msg) ->
      msg.reply 'Please enter a date in the format YYYY-MM-DD:'
      dialogCardOptions.addChoice /(.*)/, (msg) ->
        trello.put "/1/cards/#{card_id}/due", {value: msg.match[1]}, (err, data) ->
          throw err if err
          console.log "The due date of #{msg.match[1]} has succesfully been added to card `#{card_id}`."
          shutdown msg
	
    dialogCardOptions.addChoice /5/, (msg) ->
      trello.get "/1/cards/#{card_id}", {attachments: true}, (err, data) ->
        throw err if err
        msg.reply "Here are the attachments on card [#{card_id}]:"
        msg.send " * #{attachment.url}" for attachment in data.attachments
        shutdown msg
	
    dialogCardOptions.addChoice /6/, (msg) ->
      msg.reply 'Please provide a web URL for the attachment.'
      dialogCardOptions.addChoice /(.*)/, (msg) ->
        trello.post "1/cards/#{card_id}/attachments", {url: msg.match[1]}, (err,data) ->
          throw err if err
          console.log "Your attachment has successfully been added to card `#{card_id}`."
          shutdown msg
	
    dialogCardOptions.addChoice /7/, (msg) ->
      trello.put "/1/cards/#{card_id}/closed", {value: true}, (err,data) ->
        throw err if err
        console.log "Card `#{card_id}` has been successfully archived."
        shutdown msg
	
    dialogCardOptions.addChoice /8/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the CheckList you wish me to go to:'
      trello.get "/1/cards/#{card_id}", {checklists: "all"}, (err,data) ->
        throw err if err
        for checklist in data.checklists
          checklists[checklist.id] = checklist
          msg.send " `#{checklist.id}` - #{checklist.name}" 
        if data.checklists.length is 0
          msg.send 'There do not appear to be any checklists on this card.'
          selectCardOptions msg, board_id, list_id, card_id
        if data.checklists.length is 1
          msg.send 'Automatically navigating to sole checklist.'
          for checklist in data.checklists
            selectCheckListOptions msg, board_id, list_id, card_id, checklist.id
        dialogCardOptions.addChoice /([a-zA-Z0-9]{24})/m, (msg) ->
          for checklist in data.checklists
            if msg.match[1] is checklist.id
              selectCheckListOptions msg, board_id, list_id, card_id, msg.match[1]
	
    dialogCardOptions.addChoice /9/, (msg) ->
      msg.reply 'Please provide a name for this Checklist:'
      dialogCardOptions.addChoice /(.*)/, (msg) ->
        trello.post "/1/cards/#{card_id}/checklists", {name: msg.match[1]}, (err,data) ->
          throw err if err
          console.log "Checklist '#{msg.match[1]}' has successfully been created on card `#{card_id}`."
          shutdown msg
      
    dialogCardOptions.addChoice /0/, (msg) ->
      shutdown msg
      
  selectCheckListOptions = (msg, board_id, list_id, card_id, checklist_id) ->
    msg.reply 'What would you like me to do with this Checklist? (Please Select a Number):'
    msg.send ' 1. View CheckItems'
    msg.send ' 2. Create New CheckItem'
    msg.send ' 3. Shutdown'
    
    dialogCheckListOptions = convo.startDialog(msg)
    
    dialogCheckListOptions.addChoice /1/, (msg) ->
      msg.reply 'Please Copy & Paste the ID of the CheckItem you wish me to go to:'
      trello.get "/1/checklists/#{checklist_id}", (err,data) ->
        throw err if err
        for checkItem in data.checkItems
          msg.send " `#{checkItem.id}` - #{checkItem.name} | #{checkItem.state}" 
        if data.checkItems.length is 0
          msg.send 'There do not appear to be any CheckItems in this Checklist.'
          selectCheckListOptions msg, board_id, list_id, card_id, checklist_id
        if data.checkItems.length is 1
          msg.send 'Automatically navigating to sole checkitem.'
          for checkItem in data.checkItems
            selectCheckItemOptions msg, board_id, list_id, card_id, checklist_id, checkItem.id
        dialogCheckListOptions.addChoice /([a-zA-Z0-9]{24})/m, (msg) ->
          for checkItem in data.checkItems
            if msg.match[1] is checkItem.id
              selectCheckItemOptions msg, board_id, list_id, card_id, checklist_id, msg.match[1]
      
    dialogCheckListOptions.addChoice /2/, (msg) ->
      msg.reply 'Please provide a name for this CheckItem:'
      dialogCheckListOptions.addChoice /(.*)/, (msg) ->
        trello.post "/1/checklists/#{checklist_id}/checkItems", {name: "#{msg.match[1]}"}, (err,data) ->
          throw err if err
          console.log "'#{msg.match[1]}' has been successfully created."
          shutdown msg
      
    dialogCheckListOptions.addChoice /3/, (msg) ->
      shutdown msg
      
  selectCheckItemOptions = (msg, board_id, list_id, card_id, checklist_id, checkitem_id) ->
    msg.reply 'What would you like to do with this CheckItem?'
    msg.send ' 1. Update CheckItem'
    msg.send ' 2. Shutdown'
    
    dialogCheckItemOptions = convo.startDialog(msg)
    
    dialogCheckItemOptions.addChoice /1/, (msg) ->
      msg.reply 'Please enter the completion statement of this CheckItem (Complete/Incomplete):'
      dialogCheckItemOptions.addChoice /(.*)/, (msg) ->
        trello.put "/1/cards/#{card_id}/checklist/#{checklist_id}/checkItem/#{checkitem_id}/state", {value: msg.match[1].toLowerCase()}, (err,data) ->
          throw err if err
          console.log "CheckItem has been successfully updated to '#{msg.match[1]}'."
          shutdown msg

    dialogCheckItemOptions.addChoice /2/, (msg) ->
      shutdown msg
	
  shutdown = (msg) ->
    console.log "TrelloConversation has reached the end of the conversation tree and has shut down successfully."