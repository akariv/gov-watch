loaded_data = null
all_books = []
#all_chapters = {}
all_tags = []
all_subjects = []

selected_book = ""
#selected_chapter = ""
search_term = ""
selected_slug = ""
skip_overview = false
BOOK = 'b'
#CHAPTER = 'c'
SLUG = 's'
SEARCHTERM = 't'

## Generate hash for current state
generate_hash = ( selected_book, search_term, slug ) ->
#   if slug
#      "!z=#{BOOK}:#{selected_book}|#{CHAPTER}:#{selected_chapter}|#{SEARCHTERM}:#{search_term}|#{SLUG}:#{slug}"
#   else
#      "!z=#{BOOK}:#{selected_book}|#{CHAPTER}:#{selected_chapter}|#{SEARCHTERM}:#{search_term}"
   if slug
      "!z=#{BOOK}:#{selected_book}|#{SEARCHTERM}:#{search_term}|#{SLUG}:#{slug}"
   else
      "!z=#{BOOK}:#{selected_book}|#{SEARCHTERM}:#{search_term}"

## Generate a fully qualified url for a given slug
generate_url = (slug) ->
    "http://#{window.location.host}/##{generate_hash( "", "", "", slug )}"

## Change page's hash - this is the way we keep (and update) our current state
update_history = (slug) ->
    await setTimeout((defer _),0)
    window.location.hash = generate_hash( selected_book, search_term, slug )

## Process page hash changes
onhashchange = ->

   # read the hash, discard first '#!z='
   hash = window.location.hash
   hash = hash[4...hash.length]

   # hash is separated to key=value parts
   splits = hash.split("|")

   slug = null
   selected_book = null
   #selected_chapter = null
   search_term = ""

   for part in splits
       [ key, value ] = part.split(":")
       if key == BOOK
          selected_book = value
       if key == SLUG
          slug = value
#       if key == CHAPTER
#          selected_chapter = value
       if key == SEARCHTERM
          search_term = value

   if not selected_book and not slug
       # fix hash to be of the correct form
       selected_book = all_books[0]
       #selected_chapter = ""
       update_history()
       return

   # select the selected book
   $("#books li.book").toggleClass('active', false)
   $("#books li.book[data-book='#{selected_book}']").toggleClass('active', true)

#   if all_chapters[selected_book]
#       # fill values in the chapters listbox
#       $("#chapters").html("<option value=''>כל הפרקים</option>")
#       for chapter in all_chapters[selected_book]
#           $("#chapters").append("<option value='#{chapter}'>#{chapter}</option>")
#   else
#       # no values there
#       $("#chapters").html("<option value=''>-</option>")

   # select the selected chapter
   #$("#chapters option[value='#{selected_chapter}']").attr('selected', 'selected')

   if search_term != ""
      show_watermark(false)
      $("#searchbox").val(search_term)

   $(".item").removeClass("bigger")
   if slug
      selected_slug = slug
      $("body").addClass("detail-view")
      $("body").removeClass("list-view")
      select_item( $(".item[rel=#{selected_slug}]") )
      $(".item").removeClass("shown")
      $(".item[rel=#{selected_slug}]").addClass("shown")
      $(".item[rel=#{selected_slug}]").addClass("bigger")
      $("#items").isotope({filter: ".shown"})
   else
      # apply these filters
      select_item(null)
      $("body").addClass("list-view")
      $("body").removeClass("detail-view")
      do_search()

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

## Handle initial loading of data, save it to Local Storage
data_callback = (data) ->
    loaded_data = data

    all_books = {}
    all_tags = {}
    all_subjects = {}

    # Collect all available books
    for rec in data
        if not all_books[rec.base.book]
            all_books[rec.base.book] = {}
        all_books[rec.base.book][rec.base.chapter] = true
        for tag in rec.base.tags
           all_tags[tag]=1
        all_subjects[rec.base.subject]=1
        gov_updates = []
        watch_updates = []
        for k,v of rec.updates
                for u in v
                        u.user = k
                        if k == 'gov'
                                gov_updates.push(u)
                        else
                                watch_updates.push(u)
        rec.gov_updates = gov_updates
        rec.watch_updates = watch_updates

    all_tags = Object.keys(all_tags)
    all_subjects = Object.keys(all_subjects)

    all_books = Object.keys(all_books)

    # Save to local storage if its available
    if localStorage
        localStorage.data = JSON.stringify(data)
        localStorage.all_books = JSON.stringify(all_books)
        localStorage.all_tags = JSON.stringify(all_tags)
        localStorage.all_subjects=JSON.stringify(all_subjects)

    # process loaded data
    process_data()

initialized = false

## Sets up the searchbox with the typeahead lookup
setup_searchbox = ->
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

    source = []
    for tag in all_tags
          source.push({type:"tag",title:tag})
    for subject in all_subjects
          source.push({type:"subject",title:subject})
    $("#searchbox").typeahead
         source: source
         items: 20
         matcher: (item) -> ~item.title.indexOf(this.query)
         valueof: (item) -> item.title
         selected: (val) ->
                         search_term = val
                         update_history()
         highlighter: (item) ->
                            highlighted_title = item.title.replace( new RegExp('(' + this.query + ')', 'ig'), ($1, match) -> '<strong>' + match + '</strong>' )
                            if item.type == "subject"
                                    return highlighted_title
                            if item.type == "tag"
                                    "<span class='searchtag'><span>#{highlighted_title}</span></span>"


## Handles the site's data (could be from local storage or freshly loaded)
process_data = ->

    # process only once
    if initialized
       return
    initialized = true

    # Fill contents to the book selection sidebox
    for book in all_books
        $("#books").prepend("<li data-book='#{book}' class='book'><a href='#'>#{book}</a></li>")

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

    $(".item").each ->
        # Timeline
        pad = (n) -> if n<10 then '0'+n else n
        today = new Date()
        today = "#{today.getFullYear()}/#{pad(today.getMonth()+1)}/#{pad(today.getDate()+1)}"

        $(this).find('.timeline .timeline-point.today').attr('data-date',today)
        timeline_items = $(this).find(".timeline .timeline-point")
        timeline_items.tsort({attr:'data-date',order:'asc'})
        timeline_items = $(this).find(".timeline .timeline-point")

        max_numeric_date = 0
        min_numeric_date = 2100 * 372
        timeline_items.each( ->
                date = $(this).attr('data-date')
                date = date.split(' ')[0].split('/')
                [year,month,day] = (parseInt(d,10) for d in date)
                numeric_date = (year * 372) + ((month-1) * 31) + (day-1)
                if isNaN(numeric_date)
                        numeric_date = 2012 * 372
                if numeric_date > max_numeric_date
                        max_numeric_date = numeric_date + 1
                if numeric_date < min_numeric_date
                        min_numeric_date = numeric_date
                $(this).attr('data-date-numeric',numeric_date)
        )

        status_to_hebrew = (status) ->
                switch status
                        when "NEW" then "טרם התחיל"
                        when "STUCK" then "תקוע"
                        when "IN_PROGRESS" then "בתהליך"
                        when "FIXED" then "יושם במלואו"
                        when "WORKAROUND" then "יושם חלקית"
                        when "IRRELEVANT" then "יישום ההמלצה כבר לא נדרש"

        status = 'NEW'
        last_percent = 10.0
        timeline_items.each( ->
                date = parseInt($(this).attr('data-date-numeric'))
                percent = (date - min_numeric_date) / (max_numeric_date - min_numeric_date) * 75.0 + 10.0
                $(this).css("top",percent+"%")
                if percent != last_percent
                         $(this).before("<li class='timeline-line status-#{status}'></li>")
                         $(this).parent().find('.timeline-line:last').css('height',(percent-last_percent)+"%")
                         $(this).parent().find('.timeline-line:last').css('top',last_percent+"%")

                status = $(this).attr('data-status') ? status
                $(this).find('.implementation-status').addClass("label-#{status}")
                $(this).find('.implementation-status').html(status_to_hebrew(status))
                last_percent = percent
        )

        # current status
        implementation_status = $(this).find('.gov-update:last').attr('data-status')
        if implementation_status in [ 'STUCK', 'WORKAROUND' ]
             $(this).find('.buxa-header').addClass('bad')
        if implementation_status in [ 'FIXED' ]
             $(this).find('.buxa-header').addClass('good')

    # Allow the DOM to sync
    await setTimeout((defer _),50)

    # Apply event handlers on the DOM, Isotope initialization
    # modify Isotope's absolute position method (for RTL)
    $.Isotope.prototype._positionAbs = ( x, y ) -> { right: x, top: y }
    # initialize Isotope
    $("#items").isotope(
        itemSelector : '.item'
        layoutMode : 'masonry'
        transformsEnabled: false
        filter: ".shown"
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

    setup_searchbox()

    # sidebox filters init
    $("#books li.book a").click ->
        selected_book = $(this).html()
        update_history()

    # sidebox sort init
    $("#sort").change ->
        sort_measure = $("#sort").val()
        $("#items").isotope({ sortBy: sort_measure })

    # item click handler
    # $(".item").click -> update_history($(this).attr('rel'))

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
    #update_sort_data = () -> $("#items").isotope( 'updateSortData', $("#items") )
    #FB.XFBML.parse( $("#items").get(0), update_sort_data )

## Item selection
select_item = (item) ->
    $('fb\\:comments').remove()
    $('fb\\:like').remove()
    $(".item").removeClass("bigger")
    if item
      item.addClass("bigger")
      $("#items").isotope( 'reLayout', -> )
      selected_slug = item.attr("rel")
      url = generate_url(selected_slug)
      item.append("<fb:like href='#{url}' send='true' width='590' show_faces='true' action='recommend' font='tahoma'></fb:like>")
      item.append("<fb:comments href='#{url}' num_posts='2' width='590'></fb:comments>")
      await
        if window.FB
            FB.XFBML.parse( item.get(0), (defer _) )
        else
            defer _
      await setTimeout( (defer _),1000 )
      $(".item[rel=#{selected_slug}]").scrollintoview()
      $("#items").isotope( 'reLayout' )
      await setTimeout( (defer _),1000 )
      $(".item[rel=#{selected_slug}]").scrollintoview()
    $("#items").isotope( 'reLayout' )

## Perform search on the site's data
do_search = ->

    # we're searching using a regular expression
    re = RegExp(search_term,"ig")

    # search on the loaded_data veriable
    for rec in loaded_data
        slug = rec.slug
        rec = rec.base

        should_show = search_term == ""
        # search the term in prespecified fields
        if search_term != ""
            for x in [ rec["recommendation"], rec["subject"], rec["result_metric"], rec["title"],  rec["chapter"], rec["subchapter"], rec["responsible_authority"]["main"], rec["responsible_authority"]["secondary"] ]
                if x
                    found = x.indexOf(search_term) >= 0
                else
                    found = false

                should_show = should_show or found

            for tag in rec.tags
                if tag == search_term
                    should_show = true

        # should_show determines if the item should be shown in the search
        should_show = should_show and ((selected_book == "") or (rec.book == selected_book)) #and ((selected_chapter == "") or (rec.chapter == selected_chapter))

        # the 'shown' class is applied to the relevant items
        $(".item[rel=#{slug}]").toggleClass("shown",should_show)

    # apply the filtering using Isotope
    $("#items").isotope({filter: ".shown"});

    await setTimeout (defer _),1000
    $(".item[rel=#{selected_slug}]").scrollintoview()


## Load the current data for the site from google docs
load_data = ->
     $.get("/api",data_callback,"json")

## On document load
$ ->
   try
        # Try to load data from the cache, to make the page load faster
        loaded_data = JSON.parse(localStorage.data)
        all_books = JSON.parse(localStorage.all_books)
        #all_chapters = JSON.parse(localStorage.all_chapters)
        all_tags = JSON.parse(localStorage.all_tags)
        all_subjects = JSON.parse(localStorage.all_subjects)
        process_data()
        # either way, load the current data to cache after a few seconds
        setTimeout( load_data, 10000 )
   catch error
        # If we don't succeed, load data immediately
        load_data()

