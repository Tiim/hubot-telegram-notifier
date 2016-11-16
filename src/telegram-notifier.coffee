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
  idle: '🌕'
  dnd: '🔴'
  offline: '❌'

module.exports = (robot) ->


  unless token? && chatId?
    robot.logger.error "HUBOT_TELEGRAM_BOT_TOKEN or HUBOT_TELEGRAM_CHAT_ID is not set, telegram-notifier will not work"
    return

  bot = new TelegramBot(token, {polling: true});

  # Save last sent message id and chat id to brain
  successHandler = (value) -> robot.brain.set 'telegramLastMsgId', {message_id: value.message_id, chat_id: value.chat.id}
  errorHandler = (error) -> robot.logger.error "Failed to send message to telegram: #{error.message}"

  getOnlineUsers = (exclude_id) ->
    array = []
    users = robot.brain.users()
    for k, u of users
      if u.status? && u.status != "offline" && u.id != exclude_id
        array.push u
    array

  # Build the list of non-offline people (online, idle, do not desturb, etc)
  buildMessage = (message, exclude_id) ->
    users = getOnlineUsers(exclude_id)
    if users.length == 0
      message += "\nNobody else is online 😢"
    else
      message += "\nThese people are online:"
      for u in users
        message += "\n#{emojis[u.status] || u.status} #{u.name}"
    message

  robot.enter (res) ->
    user = res.message.user
    robot.logger.info "#{user.name} joined"
    p = bot.sendMessage chatId, buildMessage("#{emojis[user.status] || user.status} #{user.name} is now online", user.id), {}
    p.then successHandler, errorHandler


  robot.leave (res) ->
    user = res.message.user
    robot.logger.info "#{user.name} left"
    id = robot.brain.get 'telegramLastMsgId'
    if id?
      p = bot.editMessageText buildMessage("❌ #{user.name} left"), id
      p.then successHandler, errorHandler
    else
      p = bot.sendMessage chatId, "❌ #{user.name} is now offline", { disable_notification: true }
      p.then successHandler, errorHandler
