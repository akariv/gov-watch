loaded_data = null

data_callback = (data) ->
    loaded_data = data
    template = $("script[name=item]").html()
    html = Mustache.to_html(template, items: data)
    $("#items").html(html)
    $("#searchbox").keyup -> do_search()

do_search = ->
    search_term = $("#searchbox").val()
    re = RegExp(search_term,"ig")
    for rec in loaded_data
        slug = rec._srcslug
        recm = rec.recommendation
        subject = rec.subject

        if search_term == ""
            found_recm = false
            found_subject = false
        else
            found_recm = recm.search(search_term) != -1
            found_subject = subject.search(search_term) != -1

        should_show = found_recm or found_subject or (search_term == "")
        $(".item[rel=#{slug}]").toggleClass("shown",should_show)
        
        if found_recm
            recm = recm.replace(search_term,"<span class='highlight'>#{search_term}</span>")
        $(".item[rel=#{slug}] .recommendation").html(recm)
        
        if found_subject
            subject = subject.replace(search_term,"<span class='highlight'>#{search_term}</span>")
        $(".item[rel=#{slug}] .subject").html(subject)
        
    window.setTimeout( -> 
                            $(".highlight").toggleClass('highlight-off',true)
                       10 )

$ -> 
   H.findRecords('data/gov/decisions/', data_callback)
   
        