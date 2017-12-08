# Description:
#   Traveling Narwhal
# Commands:
#   traveling dest list - get registed members
#   traveling dest add :name - regist member
#   traveling dest del :name
#   traveling where - get who is praised
#   traveling recommend :name :reason - praise someone
#   traveling clearall - clear memory

cronJob = require('cron').CronJob
random = require('hubot').Response::random

module.exports = (robot) ->
  keydest = 'dest'
  keystay = 'stay'
  keytime = 'deptime'
  envelope = room: "#general"
  length = 1000

  getMembers = ->
    robot.brain.get(keydest) ? []

  sleep = (ms) ->
    start = new Date().getTime()
    continue while new Date().getTime() - start < ms

  # get registerd members
  robot.hear /traveling dest list/i, (msg) ->
    members = getMembers()
    msg.send members.toString()

  # get where staying
  robot.hear /traveling where/i, (msg) ->
    stay = robot.brain.get(keystay)
    unless stay?
      msg.send "I'm here"
      return

    msg.send "I'm staying at #{stay}"

  # regist member
  robot.hear /traveling dest add (.+)/i, (msg) ->
    member = msg.match[1]
    members = getMembers()
    if member in members
       msg.send "#{member} already registerd."
       return

    if members.length is 0
       tmpMembers = []
    else
       tmpMembers = members

    tmpMembers.push member

    robot.brain.set keydest, tmpMembers
    msg.send "Candidate sites of my journey -> #{tmpMembers.toString()}"

  # delete member
  robot.hear /traveling dest del (.+)/i, (msg) ->
    member = msg.match[1]
    members = getMembers()
    tmpMembers = []
    for val in members
       if member isnt val
          tmpMembers.push val

    robot.brain.set keydest, tmpMembers
    msg.send "Candidate sites of my journey -> #{tmpMembers.toString()}"

  # indicate the next destination
  robot.hear /traveling recommend (.+?) (.+)/i, (msg) ->
    user = msg.message.user.name
    member = msg.match[1]
    reason = msg.match[2]
    members = getMembers()
    
    stay = robot.brain.get(keystay)
    if ! stay?  && user isnt stay
       msg.send "I want to hear the recommendation of #{stay}"
       return

    if member not in members
       msg.send "I don't know #{member}."
       return

    tmpTime = robot.brain.get(keytime) ? 0 
    d = new Date
    if d.getTime() - tmpTime < length
       msg.send "I want stay here longer"
       return

    msg.send "@#{user} Got it! I'm leave for #{member}. Thanks for everything!"
    msg.send "@#{member} Hi,I'm just coming here from #{user}! Here is #{user}'s message -> #{reason}"

    robot.brain.set keytime, d.getTime()
    robot.brain.set keystay, member
 
  # clear memory
  robot.hear /traveling clearall/i, (msg) ->
    robot.brain.remove keystay
    robot.brain.remove keydest
    robot.brain.remove keytime
   
  # tweet sometimes
  new cronJob('0 0,30 10-18 * * *', () ->
    stay = robot.brain.get(keystay)
    unless stay?
      return

    result = random [
        "#{stay} is so nice guy!"
        "I'm happy to be with #{stay}"
        "I'm on the sight"
    ]
    robot.send envelope, "#{result}"
  ).start()

  # departure
  new cronJob('0 15,45 10-18 * * *', () ->
    tmpTime = robot.brain.get(keytime) 
    unless tmpTime?
      return

    d = new Date
    if d.getTime() - tmpTime > length
      stay = robot.brain.get(keystay) 
      robot.send envelope, "@#{stay} Now I have to go. Where is your recommendation?"
  ).start()


