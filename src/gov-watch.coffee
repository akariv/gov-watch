loaded_data = null
all_books = []
all_chapters = {}

selected_book = ""
selected_chapter = ""

update_history = ->
    hash = "#{selected_book}//#{selected_chapter}"
    window.location.hash = hash

onhashchange = ->
   hash = window.location.hash
   hash = hash[1...hash.length]
   splits = hash.split('//')
   if splits.length == 2
       [ selected_book, selected_chapter ] = splits
       $("#books option[value='#{selected_book}']").attr('selected', 'selected')

       if all_chapters[selected_book]
           $("#chapters").html("<option value=''>כל הפרקים</option>")
           for chapter in all_chapters[selected_book]
               $("#chapters").append("<option value='#{chapter}'>#{chapter}</option>")
       else
           $("#chapters").html("<option value=''>-</option>")

       $("#chapters option[value='#{selected_chapter}']").attr('selected', 'selected')

       do_search()
   else
       selected_book = ""
       selected_chapter = ""
       update_history()

wm_shown = false
show_watermark = (show) ->
    if show
       $("#searchbox").val("חיפוש חופשי בתוך ההמלצות")
    else
        if wm_shown
            $("#searchbox").val("")
    wm_shown = show
    $("#searchbox").toggleClass('watermark',show)

gs_data_callback = (data) ->
    entries = data.feed.entry
    field_titles = {}
    loaded_data=[]
    for entry in entries
        cell = entry.gs$cell
        row = parseInt(cell.row)
        col = parseInt(cell.col)
        contents = cell.$t
        if not contents
            contents = ""
        if row == 1
            field_titles[col] = contents
        else
            idx = row-2
            field = field_titles[col]
            if col == 1
                loaded_data[idx] = { '_srcslug':"#{row}"}
            loaded_data[idx][field] = contents

    data_callback(loaded_data)
window.gs_data_callback = gs_data_callback

h_data_callback = (data) ->
    get_slug = (x) -> parseInt(x._src.split('/')[3])
    data = data.sort( (a,b) -> get_slug(a) - get_slug(b) )

    loaded_data = data
    data_callback(loaded_data)

data_callback = (data) ->
    all_books = {}
    for rec in data
        if not all_books[rec.book]
            all_books[rec.book] = {}
        all_books[rec.book][rec.chapter] = true

    all_chapters = {}
    for book, chapters of all_books
        all_chapters[book] = Object.keys(chapters)

    all_books = Object.keys(all_books)

    if localStorage
        localStorage.data = JSON.stringify(data)
        localStorage.all_books = JSON.stringify(all_books)
        localStorage.all_chapters = JSON.stringify(all_chapters)

    process_data()

process_data = ->

    $("#books").html("<option value=''>הכל</option>")
    for book in all_books
        $("#books").append("<option value='#{book}'>#{book}</option>")

    template = $("script[name=item]").html()
    list_template = $("script[name=list]").html()
    html = Mustache.to_html(template,
                            items: loaded_data,
                            none_val: ->
                                (text,render) ->
                                    text = render(text)
                                    if text == ""
                                        "אין"
                                    else
                                        text
                            semicolon_list: ->
                                (text,render) ->
                                    text = render(text)
                                    text = text.split('; ')
                                    text = Mustache.to_html(list_template,"items":text)

                            )
    $("#items").html(html)
    item_hoveroff = () ->
                      $(this).find(".buxa-footer").html("")
    item_hoveron = () ->
                      html = "<div id='disqus_threaddsad' style='height:300px'></div><a href='http://disqus.com' class='dsq-brlink'>blog comments powered by <span class='logo-disqus'>Disqus</span></a>"
                      if not window.DISQUS
                            html += "<script type='text/javascript' async='true' src='http://govwatch.disqus.com/embed.js'/>"
                      window.disqus_identifier = 'recommendation'+$(this).attr('rel')
                      window.disqus_title = $(this).attr('title')
                      window.disqus_url = "http://gov-watch.org.il/#!"+window.disqus_identifier
                      $(this).find(".buxa-footer").html(html)
                      disqus_params = 
                            reload: true
                            config: () ->  
                               @page.identifier = window.disqus_identifier
                               @page.title = window.disqus_title
                               @page.url = window.disqus_url
                      if window.DISQUS
                            window.DISQUS.reset( disqus_params ) 
    $(".item").hover( item_hoveron, item_hoveroff )
    
    show_watermark(true)
    $("#searchbox").change -> do_search()
    $("#searchbox").focus ->
        show_watermark(false)
    $("#searchbox").blur ->
        if $(this).val() == ""
            show_watermark(true)
    $("#books").change ->
        selected_book = $("#books").val()
        selected_chapter = ""
        update_history()
    $("#chapters").change ->
        selected_chapter = $("#chapters").val()
        update_history()

    window.onhashchange = onhashchange
    onhashchange()

do_search = ->
    if wm_shown
        search_term = ""
    else
        search_term = $("#searchbox").val()
    re = RegExp(search_term,"ig")
    for rec in loaded_data
        slug = rec._srcslug

        should_show = search_term == ""
        new_fields = {}

        for field in [ "recommendation", "subject", "result_metric", "title" ]
            if search_term == ""
                found = false
            else
                if rec[field]
                        found = rec[field].search(search_term) != -1
                        new_fields[field] = rec[field].replace(search_term,"<span class='highlight'>#{search_term}</span>")
                else
                        found = false
                        new_fields[field] = null

            should_show = should_show or found

        should_show = should_show and ((selected_book == "") or (rec.book == selected_book)) and ((selected_chapter == "") or (rec.chapter == selected_chapter))

        $(".item[rel=#{slug}]").toggleClass("shown",should_show)

        $(".item[rel=#{slug}] .recommendation-text").html(new_fields["recommendation"])
        $(".item[rel=#{slug}] .subject").html(new_fields["subject"])
        $(".item[rel=#{slug}] .result_metric-text").html(new_fields["result_metric"])
        $(".item[rel=#{slug}] .title").html(new_fields["title"])


    window.setTimeout( ->
                            $(".highlight").toggleClass('highlight-off',true)
                       10 )

version_callback = (data) ->
   if localStorage
       current_version = localStorage.version ? null
       localStorage.version = data.update_date
       if data.update_date != current_version
           H.findRecords('data/gov/decisions/', data_callback)

$ ->
   json_data = localStorage?.data
   json_all_books = localStorage?.all_books
   json_all_chapters = localStorage?.all_chapters
   json_version = localStorage?.version
   if json_data and json_all_books and json_all_chapters and json_version
        loaded_data = JSON.parse(json_data)
        all_books = JSON.parse(json_all_books)
        all_chapters = JSON.parse(json_all_chapters)
        process_data()
#   H.getRecord('data/gov/decisions', version_callback)
   $.get("https://spreadsheets.google.com/feeds/cells/0AurnydTPSIgUdE5DN2J5Y1c0UGZYbnZzT2dKOFgzV0E/od6/public/values?alt=json-in-script",gs_data_callback,"jsonp");
#   $.get("/Users/adam/workspace/gov-watch/src/values.json",gs_data_callback,"jsonp");

   window.disqus_shortname = 'govwatch';
   window.disqus_url = 'gov-watch.org.il'
   window.disqus_developer = 1

