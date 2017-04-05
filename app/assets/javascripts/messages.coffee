# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


$(document).on "turbolinks:load", ->
  $("#messages").scrollTop $("#messages")[0].scrollHeight
  $('#message_content').on 'keydown', (event) ->
    if event.keyCode is 13 && !event.shiftKey
      $('input').click()
      event.target.value = ''
      event.preventDefault()
