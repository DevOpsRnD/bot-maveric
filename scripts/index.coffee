# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
fs = require 'fs'
path = require 'path'

# Load Environment Variables
require('dotenv').config()

# Load application settings for Maveric
config = require('../config.json')[process.env.NODE_ENV || 'development']

module.exports = (robot, scripts) ->

  robot.config = config

  if !config.adapter
    console.log("Adapter not found. Please configure adapter.")
    process.exit(1)
  
  adaptersPath = path.resolve(__dirname, 'adapters')

  if fs.existsSync adaptersPath
    for script in fs.readdirSync(adaptersPath)
      continue if script != "#{config.adapter}.coffee"
      if scripts? and '*' not in scripts
        robot.loadFile(adaptersPath, script) if script in scripts
      else
        robot.loadFile(adaptersPath, script)

  appsPath = path.resolve(__dirname, 'apps')
  if fs.existsSync appsPath
    appList = config.apps
    for app in appList
      appPath = path.resolve(appsPath, app)

      if fs.existsSync appPath
        for script in fs.readdirSync(appPath)
          robot.loadFile(appPath, script)
