Trello = require('node-trello');

class TrelloExtended extends Trello {
  constructor(key, token) {

    super(key, token);

    this.board = {}
    this.lists = {}
    this.members = {}

    if(this.ensureConfig()) {
    }
  }

  /* verify that all the environment vars are available */
  ensureConfig() {
    if(!process.env.HUBOT_TRELLO_KEY)
      console.log("Error: Trello app key is not specified");
    if(!process.env.HUBOT_TRELLO_TOKEN)
      console.log("Error: Trello token is not specified");
    if(!process.env.HUBOT_TRELLO_BOARD)
      console.log("Error: Trello board ID is not specified");
    if(process.env.HUBOT_TRELLO_KEY && process.env.HUBOT_TRELLO_TOKEN && process.env.HUBOT_TRELLO_BOARD)
      return true;
    else
      false
  }
}
module.exports = TrelloExtended

// global.trelloExt = new TrelloExtended(process.env.HUBOT_TRELLO_KEY, process.env.HUBOT_TRELLO_TOKEN);
