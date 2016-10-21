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

module.exports = (robot) ->


  unless token? && chatId?
    robot.logger.error "HUBOT_TELEGRAM_BOT_TOKEN or HUBOT_TELEGRAM_CHAT_ID is not set, telegram-notifier will not work"
    return

  bot = new TelegramBot(token, {polling: true});

  robot.enter (res) ->
    promise = bot.sendMessage chatId, "#{res.message.user.name} joined", {}
    promise.catch (err) -> robot.logger.error err
  robot.leave (res) ->
    promise = bot.sendMessage chatId, "#{res.message.user.name} left", { disable_notification: true }
    promise.catch (err) -> robot.logger.error err
