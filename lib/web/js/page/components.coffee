$(document).ready ->
  $.get '/repository/json/components', (data) ->
    for component in data
      template = $($('#component').html())
      template.find(".name").text(component)
      $('body').append template
