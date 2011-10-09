data_callback = (data) ->
    template = $("script[name=item-template]").html()
    html = Mustache.to_html(template, data)
    $("#container").html(html)

$ -> 
   bla
   