$( () ->
        await $.getJSON("http://127.0.0.1:5000/api",(defer data))
        for item in data
                $("#list").append("<div class='row'>
                                         <div class='span7'>#{item.subject}</div>
                                         <a href='/edit##{item.slug}' class='span1 btn btn-small btn-primary'>Edit</a>
                                   </div>")
)
