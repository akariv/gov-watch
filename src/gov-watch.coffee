loaded_data = null
all_books = []
all_chapters = {}

selected_book = ""
selected_chapter = ""
search_term = ""
selected_slug = ""
skip_overview = false
BOOK = 'b'
CHAPTER = 'c'
SLUG = 's'
SEARCHTERM = 't'

## Generate hash for current state
generate_hash = ( selected_book, selected_chapter, search_term, slug ) ->
   if slug
      "!z=#{BOOK}:#{selected_book}|#{CHAPTER}:#{selected_chapter}|#{SEARCHTERM}:#{search_term}|#{SLUG}:#{slug}"
   else
      "!z=#{BOOK}:#{selected_book}|#{CHAPTER}:#{selected_chapter}|#{SEARCHTERM}:#{search_term}"

## Generate a fully qualified url for a given slug
generate_url = (slug) ->
    "http://#{window.location.host}/##{generate_hash( "", "", "", slug )}"

## Change page's hash - this is the way we keep (and update) our current state
update_history = ->
    setTimeout( 
                () -> 
                    window.location.hash = generate_hash( selected_book, selected_chapter, search_term )
               ,
                0 
              )

## Process page hash changes
onhashchange = ->

   # read the hash, discard first '#!z='
   hash = window.location.hash
   hash = hash[4...hash.length]
   
   # hash is separated to key=value parts
   splits = hash.split("|")

   slug = null
   selected_book = null
   selected_chapter = null
   search_term = ""
       
   for part in splits
       [ key, value ] = part.split(":")
       if key == BOOK
          selected_book = value
       if key == SLUG
          slug = value
       if key == CHAPTER
          selected_chapter = value
       if key == SEARCHTERM
          search_term = value

   if not selected_book
       # fix hash to be of the correct form
       selected_book = all_books[0]
       selected_chapter = ""
       update_history()
       return
       
   # select the selected book
   $("#books option[value='#{selected_book}']").attr('selected', 'selected')

   if all_chapters[selected_book]
       # fill values in the chapters listbox
       $("#chapters").html("<option value=''>כל הפרקים</option>")
       for chapter in all_chapters[selected_book]
           $("#chapters").append("<option value='#{chapter}'>#{chapter}</option>")
   else
       # no values there
       $("#chapters").html("<option value=''>-</option>")

   # select the selected chapter
   $("#chapters option[value='#{selected_chapter}']").attr('selected', 'selected')

   if search_term != ""
      show_watermark(false)
      $("#searchbox").val(search_term)

   # apply these filters
   do_search()
   
   if slug
      selected_slug = slug
      skip_overview = true

## Watermark handling
wm_shown = false
show_watermark = (show) ->
    if show
       $("#searchbox").val("חיפוש חופשי בתוך ההמלצות")
    else
        if wm_shown
            $("#searchbox").val("")
    wm_shown = show
    $("#searchbox").toggleClass('watermark',show)

## Parse data received from the Google Docs API
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

    # call data_callback after normalizing data
    data_callback(loaded_data)
window.gs_data_callback = gs_data_callback # for jsonp handling

## Handle initial loading of data, save it to Local Storage
data_callback = (data) ->
    all_books = {}
    
    # Collect all available books
    for rec in data
        if not all_books[rec.book]
            all_books[rec.book] = {}
        all_books[rec.book][rec.chapter] = true

    # Collect all chapters for every book
    all_chapters = {}
    for book, chapters of all_books
        all_chapters[book] = Object.keys(chapters)

    all_books = Object.keys(all_books)

    # Save to local storage if its available
    if localStorage
        localStorage.data = JSON.stringify(data)
        localStorage.all_books = JSON.stringify(all_books)
        localStorage.all_chapters = JSON.stringify(all_chapters)

    # process loaded data 
    process_data()

initialized = false

## Handles the site's data (could be from local storage or freshly loaded)
process_data = ->

    # process only once
    if initialized
       return
    initialized = true

    # Fill contents to the book selection sidebox
    $("#books").html("<option value=''>\u05d4\u05db\u05dc</option>")
    for book in all_books
        $("#books").append("<option value='#{book}'>#{book}</option>")

    # This is used to process lists in the data's values.
    # Lists are srtings separated with ';'
    template = $("script[name=item]").html()
    list_template = $("script[name=list]").html()
    do_list = (text) ->
        Mustache.to_html( list_template,
                          items:text
                          # linkify converts [xxx] to <a href='xxx'>...</a>
                          linkify: ->
                            (text,render) ->
                               text = render(text)
                               text = text.replace( /\[(.+)\]/, "<a href='$1'>\u05e7\u05d9\u05e9\u05d5\u05e8</a>" )
                        )

    # Run the main template on the loaded data
    html = Mustache.to_html(template,
                            items: loaded_data
                            none_val: ->
                                (text,render) ->
                                    text = render(text)
                                    if text == ""
                                        "\u05d0\u05d9\u05df"
                                    else
                                        text
                            semicolon_list: ->
                                (text,render) ->
                                    text = render(text)
                                    text = text.split(';')
                                    text = do_list(text)
                            urlforslug: ->
                                (text,render) ->
                                    text = render(text)
                                    generate_url( text )
                            )
    # Update the document with rendered HTML
    $("#items").html(html)
    # Allow the DOM to sync
    setTimeout( start_handlers, 50 )

## Apply event handlers on the DOM, Isotope initialization    
start_handlers = ->
    # modify Isotope's absolute position method (for RTL)
    $.Isotope.prototype._positionAbs = ( x, y ) -> { right: x, top: y }
    # initialize Isotope
    $("#items").isotope(  
        itemSelector : '.item'
        layoutMode : 'masonry'
        transformsEnabled: false
        getSortData :
           chapter :  ( e ) -> e.find('.chapter-text').text()
           recommendation :  ( e ) -> e.find('.recommendation-text').text()
           budget :  ( e ) -> 
                        -parseInt( "0"+e.attr('cost'), 10 )
           comments :  ( e ) -> 
                        -parseInt( "0"+e.find('.fb_comments_count').text(), 10 )
           oneitem : ( e ) -> 
                    if e.attr("rel") == selected_slug
                       0
                    else
                       1
    )
    # Searchbox init
    show_watermark(true)
    $("#searchbox").change -> 
       # handle watermark on the search box
       if wm_shown
            search_term = ""
       else
            search_term = $("#searchbox").val()
       update_history()
    $("#searchbox").focus ->
        show_watermark(false)
    $("#searchbox").blur ->
        if $(this).val() == ""
            show_watermark(true)
    $("#searchbar").submit -> false
            
    # sidebox filters init
    $("#books").change ->
        selected_book = $("#books").val()
        selected_chapter = ""
        update_history()
    $("#chapters").change ->
        selected_chapter = $("#chapters").val()
        update_history()
    
    # sidebox sort init
    $("#sort").change ->
        sort_measure = $("#sort").val()
        $("#items").isotope({ sortBy: sort_measure })
    
    # item click handler
    $(".item").click -> select_item( $(this) )

    # handle hash change events, and process current (initial) hash
    window.onhashchange = onhashchange
    onhashchange()

    # create overview modal
    modal_options = 
       backdrop: true
       keyboard: true
       show: false
    $("#overview").modal( modal_options )
    $("#overview-close").click -> $("#overview").modal('hide')
    
    FB.XFBML.parse( $("#items").get(0),
                    () -> $("#items").isotope( 'updateSortData', $("#items") )
                  )
    
    if skip_overview
        select_item( $(".item[rel=#{selected_slug}]") )
    else
        $("#overview").modal('show')

## Item selection
select_item = (item) ->
    $('fb\\:comments').remove()
    $('fb\\:like').remove()
    if item.hasClass("bigger")
        item.removeClass("bigger")
        $("#items").isotope( 'reLayout', -> )        
    else
        $(".item").removeClass("bigger")
        item.addClass("bigger")
        $("#items").isotope( 'reLayout', -> )        
        selected_slug = item.attr("rel")
        url = generate_url(selected_slug)
        item.append("<fb:like href='#{url}' send='true' width='590' show_faces='true' action='recommend' font='tahoma'></fb:like>")
        item.append("<fb:comments href='#{url}' num_posts='2' width='590'></fb:comments>")
        FB.XFBML.parse( item.get(0), 
                        () -> 
                            setTimeout( () -> 
                                             $("#items").isotope( 'reLayout' )
                                             setTimeout( 
                                                         () ->
                                                             $(".item[rel=#{selected_slug}]").scrollintoview()
                                                         , 
                                                         1000 )
                                       , 1000  )
                       )
    $("#items").isotope( 'reLayout' )

## Perform search on the site's data
do_search = ->
        
    # we're searching using a regular expression
    re = RegExp(search_term,"ig")
    
    # search on the loaded_data veriable
    for rec in loaded_data
        slug = rec._srcslug

        should_show = search_term == ""
        new_fields = {}

        # search the term in prespecified fields
        for field in [ "recommendation", "subject", "result_metric", "title", "execution_metric", "chapter", "responsible_authority"]
            if search_term == ""
                found = false
            else
                if rec[field]
                        found = rec[field].search(search_term) != -1
                        # we replace the text of the item with the highlight span
                        new_fields[field] = rec[field].replace(search_term,"<span class='highlight'>#{search_term}</span>")
                else
                        found = false
                        new_fields[field] = null

            should_show = should_show or found

        # should_show determines if the item should be shown in the search
        should_show = should_show and ((selected_book == "") or (rec.book == selected_book)) and ((selected_chapter == "") or (rec.chapter == selected_chapter))

        # the 'shown' class is applied to the relevant items
        $(".item[rel=#{slug}]").toggleClass("shown",should_show)

        # replace the items text with the new text (incl. highlight span)
        $(".item[rel=#{slug}] .chapter-text").html(new_fields["chapter"])
        $(".item[rel=#{slug}] .recommendation-text").html(new_fields["recommendation"])
        $(".item[rel=#{slug}] .execution_metric-text").html(new_fields["execution_metric"])
        $(".item[rel=#{slug}] .responsible_authority-text").html(new_fields["responsible_authority"])
        $(".item[rel=#{slug}] .subject-text").html(new_fields["subject"])
        $(".item[rel=#{slug}] .result_metric-text").html(new_fields["result_metric"])
        $(".item[rel=#{slug}] .title-text").html(new_fields["title"])

    # apply the filtering using Isotope
    $("#items").isotope({filter: ".shown"});

    # start the fading of the highlight spans
    window.setTimeout( ->
                            $(".highlight").toggleClass('highlight-off',true)
                       10 )

## Load the current data for the site from google docs
load_from_gdocs = ->
     $.get("https://spreadsheets.google.com/feeds/cells/0AurnydTPSIgUdE5DN2J5Y1c0UGZYbnZzT2dKOFgzV0E/od6/public/values?alt=json-in-script",gs_data_callback,"jsonp")

## On document load
$ ->
   try
        # Try to load data from the cache, to make the page load faster
        loaded_data = JSON.parse(localStorage.data)
        all_books = JSON.parse(localStorage.all_books)
        all_chapters = JSON.parse(localStorage.all_chapters)
        process_data()
        # either way, load the current data to cache after a few seconds
        setTimeout( load_from_gdocs, 10000 )
   catch error
        # If we don't succeed, load data from gdocs immediately
        load_from_gdocs()

