# Description
#   Remind users to give a daily status update
#
# Commands:
#   status reminder add user <username> - Add a user
#   status reminder remove user <username> - Remove a user
#   status reminder list users - List all users getting reminders and show stats
#   status reminder send reminders - Send reminders
#
# Notes:
#   You can use package hubot-cron-json to execute the send reminders task
#   at a certain time. Update conf/cron-tasks.json to set the time.
#
# Author:
#   nick warner
#   Ville Saarinen

module.exports = (robot) ->
  robot.brain.data.status_reminder ||= {}
  robot.brain.data.status_reminder.users ||= []

  seconds_since_midnight = ->
    d = new Date()
    e = new Date(d)
    e - d.setHours(0,0,0,0)

  send_reminders = ->
    for user in robot.brain.data.status_reminder.users
      if user.last_status_date < (new Date().getTime()) - seconds_since_midnight()
        message = "Hey #{user.username}! Please update your daily status. Thanks!"
        robot.send {user: {name: user.username, id: user.user.id}}, message

  robot.respond /status reminder add user\s+(.*)?$/i, (msg) ->
    username = msg.match[1]
    username = username.replace(/^@/, '') # remove @ symbol from front if it exists
    if username in robot.brain.data.status_reminder.users.map((user) -> user.username)
      msg.send "Reminders are already being sent for @#{username}"
      return
    hubotUser = robot.brain.userForName(username)
    unless hubotUser
      msg.send "No such user @#{username}"
      return
    user =
      streak: 0
      last_status_date: 0
      username: username
      user: hubotUser
    robot.brain.data.status_reminder.users.push user
    msg.send "Added user: @#{username}"

  robot.respond /status reminder remove user\s+(.*)?$/i, (msg) ->
    username = msg.match[1]
    username = username.replace(/^@/, '') # remove @ symbol from front if it exists
    users = robot.brain.data.status_reminder.users
    robot.brain.data.status_reminder.users = users.filter (user) ->
      user.username != username
    msg.send "Removed user: @#{username}"

  robot.respond /status reminder list users/i, (msg) ->
    for user in robot.brain.data.status_reminder.users
      date = new Date(user.last_status_date)
      msg.send "@#{user.username}: Last update at #{date.toLocaleDateString()}"

  robot.respond /status reminder send reminders/i, ->
    send_reminders()

  robot.on /status reminder send reminders/i, ->
    send_reminders()

  robot.hear /^t:|^today|^y:|^yesterday/i, (msg) ->
    username = msg.message.user.name
    users = robot.brain.data.status_reminder.users
    index = users.map((user) -> user.username).indexOf(username)
    if index > -1
      robot.brain.data.status_reminder.users[index].last_status_date = (new Date().getTime())
    #TODO record streak data
