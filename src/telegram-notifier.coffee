# Description:
#   Telegram Notifier
#
#   Notifies a telegram chat if a user enters or leaves the chat
#   where this bot is in.
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_TELEGRAM_BOT_TOKEN
#   HUBOT_TELEGRAM_CHAT_ID
#
# Commands:
#
# Author:
#   Tiim

TelegramBot = require 'node-telegram-bot-api'

token = process.env.HUBOT_TELEGRAM_BOT_TOKEN
chatId = process.env.HUBOT_TELEGRAM_CHAT_ID

emojis =
  online: '✅'
  idle: '🔴'
  dnd: '🌕'
  offline: '❌'

module.exports = (robot) ->


  unless token? && chatId?
    robot.logger.error "HUBOT_TELEGRAM_BOT_TOKEN or HUBOT_TELEGRAM_CHAT_ID is not set, telegram-notifier will not work"
    return

  bot = new TelegramBot(token, {polling: true});

  successHandler = (value) -> robot.brain.set 'telegramLastMsgId', {message_id: value.message_id, chat_id: value.chat.id}
  errorHandler = (error) -> robot.logger.error error

  buildMessage = (message, exclude_id) ->
    users = robot.brain.users()
    for k, u of users
      if u.status? && u.status != "offline" && u.id != exclude_id
        message += "\n#{emojis[u.status] || u.status} #{u.name}"
    message

  robot.enter (res) ->
    robot.logger.info "User joined"
    p = bot.sendMessage chatId, buildMessage("✅ #{res.message.user.name} is now online", res.message.user.id), {}
    p.then successHandler, errorHandler


  robot.leave (res) ->
    robot.logger.info "User left"
    id = robot.brain.get 'telegramLastMsgId'
    if id?
      p = bot.editMessageText buildMessage("These people are now online:"), id
      p.then successHandler, errorHandler
    else
      p = bot.sendMessage chatId, "❌ #{res.message.user.name} is now offline", { disable_notification: true }
      p.then successHandler, errorHandler
