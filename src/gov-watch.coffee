data_callback = (data) ->
    template = $("script[name=item]").html()
    html = Mustache.to_html(template, items: data)
    $("#container").html(html)

$ -> 
   H.findRecords('data/gov/decisions/', data_callback)
   