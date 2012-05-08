$( () ->
        await $.getJSON("/api",(defer data))
        for item in data
                $("#list").append("<div class='row'>
                                         <div class='span7' style='color:white;'>#{item['base']['subject']}</div>
                                         <a href='/edit##{item.slug}' class='span2 btn btn-small btn-primary'>עריכת נתוני בסיס</a>
                                         <a href='/udpate##{item.slug}' class='span1 btn btn-small btn-primary'>עדכון סטטוס</a>
                                   </div>")
)
