App.chatting = App.cable.subscriptions.create "ChattingChannel",
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    $('#message_content').val ""
    $('#messages').append "<li>" + data.message_user.email.split('@')[0] + " : " + data.content + "</li>"
    $('#messages').scrollTop $('#messages')[0].scrollHeight
