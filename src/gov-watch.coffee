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


data_callback = (data) ->
    get_slug = (x) -> parseInt(x._src.split('/')[3])
    data = data.sort( (a,b) -> get_slug(a) - get_slug(b) )

    loaded_data = data

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
    list_template = $("script[name=list").html()
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
                                    text = Mustache.to_html(list_template,items:text)
                                    render(text)

                            )
    $("#items").html(html)
    show_watermark(true)
    $("#searchbox").keyup -> do_search()
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

$ ->
   json_data = localStorage?.data
   json_all_books = localStorage?.all_books
   json_all_chapters = localStorage?.all_chapters
   if json_data and json_all_books and json_all_chapters
        loaded_data = JSON.parse(json_data)
        all_books = JSON.parse(json_all_books)
        all_chapters = JSON.parse(json_all_chapters)
        process_data()
   else
        H.findRecords('data/gov/decisions/', data_callback)

