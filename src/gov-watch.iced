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

status_filter = null

slugify = (str) ->
        str2 = ""
        if str == ""
                return ""
        for x in [0..str.length-1]
                ch = str.charAt(x)
                co = str.charCodeAt(x)
                if co >= 0x5d0 and co < 0x600
                        co = co - 0x550
                if co < 256
                        str2+=(co+0x100).toString(16).substr(-2).toUpperCase();
        str2

unslugify = (str) ->
        str2 = ""
        if str == ""
                return ""
        for x in [0..(str.length/2)-1]
                ch = str[x*2..x*2+1]
                ch = parseInt(ch,16)
                if ch >= 128
                        ch += 0x550
                str2 = str2 + String.fromCharCode(ch)
        str2

## Generate hash for current state
generate_hash = ( selected_book, search_term, slug ) ->
   if slug
      "!z=#{BOOK}:#{slugify(selected_book)}_#{SLUG}:#{slug}"
   else
      "!z=#{BOOK}:#{slugify(selected_book)}_#{SEARCHTERM}:#{slugify(search_term)}"

## Generate a fully qualified url for a given slug
generate_url = (slug) ->
    "http://#{window.location.host}/##{generate_hash( selected_book, "", slug )}"

## Change page's hash - this is the way we keep (and update) our current state
update_history = (slug) ->
    await setTimeout((defer _),0)
    window.location.hash = generate_hash( selected_book, search_term, slug )

set_title = (title) ->
        $("title").html(title)

## Process page hash changes
onhashchange = ->

   # read the hash, discard first '#!z='
   fullhash = window.location.hash

   hash = fullhash[4...fullhash.length]

   # hash is separated to key=value parts
   splits = hash.split("_")

   slug = null
   selected_book = null
   search_term = ""

   for part in splits
       [ key, value ] = part.split(":")
       if key == BOOK
          selected_book = unslugify(value)
       if key == SLUG
          slug = value
       if key == SEARCHTERM
          search_term = unslugify(value)

   if not selected_book and not slug
       # fix hash to be of the correct form
       selected_book = all_books[0]
       update_history()
       return

   # select the selected book
   $("#books li.book").toggleClass('active', false)
   $("#books li.book[data-book='#{selected_book}']").toggleClass('active', true)

   if search_term != ""
      show_watermark(false)
      $("#searchbox").val(search_term)

   if slug
        selected_slug = slug
        select_item( selected_slug )
        $(".item").removeClass("shown")
        $("#items").isotope({filter: ".shown"})
    else
        set_title('דו"ח טרכטנברג | המפקח: מעקב אחר ישום המלצות הועדה')
        selected_slug = null
        select_item( null )
        do_search()

   # Google analytics
   `_gaq.push(['_trackPageview', '/'+fullhash]);`

## Watermark handling
wm_shown = false
show_watermark = (show) ->
    if show
       $("#searchbox").val("סינון חופשי של ההמלצות")
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
        num_links = {}
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
                        if u.links
                                for l in u.links
                                        num_links[l.url] = true
        rec.base.num_links = Object.keys(num_links).length
        rec.gov_updates = gov_updates
        rec.watch_updates = watch_updates
        rec.base.subscribers = rec.subscribers ? 0

        if rec.base.recommendation?.length > 500
                rec.base.recommendation_shortened = rec.base.recommendation[0..500] + "&nbsp;" +"<a href='#{generate_url(rec.slug)}'>" + "עוד..." +"</a>"
        else
                rec.base.recommendation_shortened = rec.base.recommendation

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
         itemfrom: (query) -> {type:"subject", title:query}
         selected: (val) ->
                search_term = val
                update_history()
         highlighter: (item) ->
                highlighted_title = item.title.replace( new RegExp('(' + this.query + ')', 'ig'), ($1, match) -> '<strong>' + match + '</strong>' )
                if item.type == "subject"
                        return highlighted_title
                if item.type == "tag"
                        "<span class='searchtag'><span>#{highlighted_title}</span></span>"

    $("#clearsearch").click ->
        search_term = ""
        show_watermark(true)
        update_history()

run_templates = (template,data,selector) ->
    # This is used to process lists in the data's values.
    # Lists are srtings separated with ';'
    template = $("script[name=#{template}]").html()

    # Run the main template on the loaded data
    html = Mustache.to_html(template,
                            data
                            )
    # Update the document with rendered HTML
    $(selector).html(html)

setup_timeline = ->
    # Setup timeline after all elements have reached their required size
    $(".item").each ->
        # Timeline
        pad = (n) -> if n<10 then '0'+n else n
        today = new Date()
        today = "#{today.getFullYear()}/#{pad(today.getMonth()+1)}/#{pad(today.getDate()+1)}"

        max_numeric_date = 0
        min_numeric_date = 2100 * 372
        $(this).find('.timeline .timeline-point.today').attr('data-date',today)

        has_unknowns = false
        $(this).find(".timeline > ul > li").each( ->
                date = $(this).find('.timeline-point:first').attr('data-date')
                date = date.split(' ')
                if (date.length > 1)
                        time = date[1]
                else
                        time = "00:00:00"
                date = date[0].split('/')
                time = time.split(':')
                [year,month,day] = (parseInt(d,10) for d in date)
                [hour,min,second] = (parseInt(t,10) for t in time)
                numeric_date = (year * 372) + ((month-1) * 31) + (day-1) + hour/24.0 + min/(24.0*60) + second/(24*60*60.0)
                if isNaN(numeric_date) or (year == 1970)
                        numeric_date = "xxx"
                        has_unknowns = true
                else
                        if numeric_date > max_numeric_date
                                max_numeric_date = numeric_date
                        if numeric_date < min_numeric_date
                                min_numeric_date = numeric_date - 1
                $(this).attr('data-date-numeric',numeric_date)

                # profile image
                img = $(this).find('img')
                alt = img?.attr('alt')
                if alt
                        img.attr('src',"/profile/#{slugify(alt)}")
        )

        if has_unknowns
                max_numeric_date += 180
                $(this).find(".timeline > ul > li[data-date-numeric='xxx']").attr('data-date-numeric',max_numeric_date)

        $(this).find(".timeline > ul > li").tsort({attr:'data-date-numeric',order:'desc'})

        status_to_hebrew = (status) ->
                switch status
                        when "NEW" then "טרם התחיל"
                        when "STUCK" then "תקוע"
                        when "IN_PROGRESS" then "בתהליך"
                        when "FIXED" then "יושם במלואו"
                        when "WORKAROUND" then "יושם חלקית"
                        when "IRRELEVANT" then "יישום ההמלצה כבר לא נדרש"

        is_good_status = (status) ->
                switch status
                        when "NEW" then false
                        when "STUCK" then false
                        when "IN_PROGRESS" then true
                        when "FIXED" then true
                        when "WORKAROUND" then false
                        when "IRRELEVANT" then true


        gov_status = 'NEW'
        last_percent = 0.0
        item_margins = 5
        margins = 80
        height = $(this).innerHeight() - margins
        available_height = height
        $(this).find(".timeline > ul > li .timeline-point").each( ->
                available_height = available_height - $(this).outerHeight() - item_margins
                )
        #available_height = height - item_size*($(this).find(".timeline > ul > li").size())
        top = 0

        conflict = false
        conflict_status = null
        late = false

        timeline_items = $(this).find(".timeline > ul > li")

        if (timeline_items.length>0) and $(timeline_items[0]).find('.timeline-point').hasClass('today')
                today_date = parseInt($(timeline_items[0]).attr('data-date-numeric'))
                last_update = parseInt($(this).find(".timeline > ul > li").attr('data-date-numeric'))
                if today_date - last_update > 180
                        late = true

        NOT_SET = 1000
        last_update_at = NOT_SET
        today_at = NOT_SET
        fixed_at = NOT_SET

        for i in [timeline_items.size()-1..0]
                el = $(timeline_items[i])
                point = el.find('.timeline-point:first')
                line = el.find('.timeline-line:first')

                status = point.attr('data-status') ? gov_status

                if point.hasClass('gov-update')
                        conflict = false
                        gov_status = status ? gov_status
                        last_update_at = i

                if (fixed_at == NOT_SET) and (gov_status == "FIXED" or gov_status == "IRRELEVANT")
                        fixed_at = i

                its_today = false
                if point.hasClass("today")
                        today_at = i
                        its_today = true

                if point.hasClass('watch-update')
                        if is_good_status(gov_status) != is_good_status(status)
                                conflict = true
                                conflict_status = status
                        if is_good_status(status)
                                point.addClass("watch-status-good")
                        else
                                point.addClass("watch-status-bad")
                        last_update_at = i

                if today_at == NOT_SET or its_today
                        point.find('.implementation-status').addClass("label-#{status}")
                        point.find('.implementation-status').html(status_to_hebrew(status))
                        line.addClass("status-#{gov_status}")

                        if conflict
                                point.addClass("conflict")

                        if point.hasClass('gov-update')
                                point.addClass("gov-#{gov_status}")
                                if is_good_status(gov_status)
                                        point.addClass("gov-status-good")
                                else
                                        point.addClass("gov-status-bad")


        for i in [timeline_items.size()-1..0]
                el = $(timeline_items[i])
                line = el.find('.timeline-line:first')

                if (fixed_at != NOT_SET and i <= fixed_at) or i <= today_at
                        line.addClass("future")
                else
                        line.addClass("past")
                        if i <= last_update_at
                                line.addClass("unreported")



        $(this).find(".timeline > ul > li").each( ->
                point = $(this).find('.timeline-point:first')
                line = $(this).find('.timeline-line:first')

                date = parseInt($(this).attr('data-date-numeric'))

                percent = (max_numeric_date - date) / (max_numeric_date - min_numeric_date)
                point_size = point.outerHeight() + item_margins
                #console.log point_size
                item_height = available_height * (percent - last_percent) + point_size
                $(this).css('height',item_height)
                $(this).css('top',top)
                last_percent = percent
                top = top + item_height
        )

        $(this).find(".timeline > ul > li:first > .timeline-line").remove()
        $(this).find(".timeline > ul > li:first").css('height','3px')

        # current status
        implementation_status = $(this).find('.gov-update:last').attr('data-status') ? "NEW"
        if conflict
                $(this).find('.buxa-header').addClass('conflict')
        else
                $(this).find('.buxa-header').removeClass('conflict')
                if is_good_status( implementation_status )
                     $(this).find('.buxa-header').addClass('good')
                else
                     $(this).find('.buxa-header').addClass('bad')
        $(this).attr('data-implementation-status',implementation_status)
        $(this).addClass("implementation-status-#{implementation_status}")

        # stamp
        status_to_stamp_class = (status) ->
                switch status
                        when "NEW" then "notstarted"
                        when "STUCK" then "stuck"
                        when "IN_PROGRESS" then "inprogress"
                        when "FIXED" then "done"
                        when "WORKAROUND" then "workaround"
                        when "IRRELEVANT" then "done"

        stamp_class = status_to_stamp_class(implementation_status)
        if late
                stamp_class = 'late'
        $(this).find('.buxa-header').before("<div class='stamp #{stamp_class}'></div>")

        if conflict
                stamp = status_to_hebrew(conflict_status)
                stamp_class = status_to_stamp_class(conflict_status)
                $(this).find('.buxa-header').before("<div class='stamp conflicting #{stamp_class}'></div>")

setup_summary = ->
        total = $(".item.shown").size()
        stuck = $(".item.shown[data-implementation-status='STUCK']").size()
        news = $(".item.shown[data-implementation-status='NEW']").size()
        in_progress = $(".item.shown[data-implementation-status='IN_PROGRESS']").size()
        fixed = $(".item.shown[data-implementation-status='FIXED']").size()
        workaround = $(".item.shown[data-implementation-status='WORKAROUND']").size()
        irrelevant = $(".item.shown[data-implementation-status='IRRELEVANT']").size()
        data = {}
        if total
                data.total = total
        stuck = news + workaround + stuck
        if stuck
                data.stuck = stuck
        implemented = fixed + irrelevant
        if implemented
                data.implemented = implemented
        if in_progress
                data.in_progress = in_progress
        run_templates( "summary", data, "#summary" )

        $("#summary .total").click ->
                status_filter = null
                do_search()
                return false
        $("#summary .stuck").click ->
                status_filter = ['STUCK','NEW','WORKAROUND']
                do_search()
                return false
        $("#summary .implemented").click ->
                status_filter = ['FIXED','IRRELEVANT']
                do_search()
                return false
        $("#summary .in_progress").click ->
                status_filter = ['IN_PROGRESS']
                do_search()
                return false

setup_subscriptions = ->
   $("#subscribe").modal({'show':false})
   $(".watch").click ->
        rel = $(this).attr('rel')
        $("#subscribe_email").attr('data-slug',rel)
        $("#subscribe_form").attr('action',"/subscribe/#{rel}")
        $("#subscribe").modal('show')
        return false
   $("#do_subscribe").click ->
        $("#subscribe_form").submit()
        return false
   $("#subscribe_form").submit ->
        $.post($(this).attr('action'),
               'email':$("#subscribe_email").val(),
                -> $("#subscribe").modal('hide'))
        return false

setup_tags = ->
   $(".tags > ul > li, a[data-tag='true']").click ->
        search_term = $(this).text()
        show_watermark(false)
        $("#searchbox").val(search_term)
        $("#explanation").modal('hide')
        update_history()


## Handles the site's data (could be from local storage or freshly loaded)
process_data = ->

    # process only once
    if initialized
       return
    initialized = true

    # Fill contents to the book selection sidebox
    for book in all_books
        $("#books").prepend("<li data-book='#{book}' class='book'><a href='#'>#{book}</a></li>")

    run_templates( "item", items: loaded_data, "#items" )

    # Explanation unit
    explanation_needed = true
    if localStorage?.explained?
        explanation_needed = false

    $("#explanation .close").click ->
        localStorage?.explained = true
        $("#explanation").modal('hide')
        return false

    $("#show-explanation").click ->
        $("#explanation").modal('show')
        return false

    # Allow the DOM to sync
    await setTimeout((defer _),50)

    # Apply event handlers on the DOM, Isotope initialization
    # modify Isotope's absolute position method (for RTL)
    $.Isotope.prototype._positionAbs = ( x, y ) -> { right: x, top: y }
    # initialize Isotope
    $("#items").isotope(
        itemSelector : '.isotope-card'
        layoutMode : 'masonry'
        transformsEnabled: false
        filter: ".shown"
        getSortData :
           followers:  ( e ) -> -parseInt( "0"+e.find('.watch').text() )
           original :  ( e ) -> "#{e.attr('data-chapter')}/{e.attr('data-subchapter')}"
           budget :  ( e ) ->
                        -parseInt( "0"+e.attr('cost'), 10 )
           comments :  ( e ) ->
                          ret = -parseInt( "0"+e.find('.commentcount').text(), 10 )
                          return ret
    )

    # Let isotope do its magic
    await setTimeout((defer _),50)

    setup_timeline()

    $(".item").css('visibility','inherit')

    setup_searchbox()

    setup_subscriptions()

    setup_tags()

    # book selection
    $("#books li.book a").click ->
        selected_book = $(this).html()
        update_history()

    # sort buttons
    $("#sort button").click ->
        $("#sort button").removeClass('active')
        $(this).addClass('active')
        sort_measure = $(this).attr('value')
        $("#items").isotope( 'updateSortData', $(".isotope-card") )
        $("#items").isotope({ sortBy: sort_measure })

    # item click handler
    # $(".item").click -> update_history($(this).attr('rel'))

    $("#explanation").modal({'show':explanation_needed})

    # handle hash change events, and process current (initial) hash
    window.onhashchange = onhashchange
    onhashchange()

    load_fb_comment_count()

## Item selection
select_item = (slug) ->
    $('fb\\:comments').remove()
    $('fb\\:like').remove()
    if slug
        $("#summary-header").css('visibility','hidden')
        $("#summary").html('')
        $("#sort button").addClass('disabled')
        for x in loaded_data
                if x.slug == slug
                        item = run_templates( "single-item", x, "#single-item" )
                        set_title( x.base.book+": "+x.base.subject )
                        url = generate_url(slug)
                        $("#single-item .fb").append("<fb:like href='#{url}' send='true' width='590' show_faces='true' action='recommend' font='tahoma'></fb:like>")
                        $("#single-item .fb").append("<fb:comments href='#{url}' num_posts='2' width='590'></fb:comments>")
                        if window.FB
                                FB.XFBML.parse( item.get(0), -> )
                        break
    else
        $("#single-item").html('')
        $("#summary-header").css('visibility','inherit')
        $("#sort button").removeClass('disabled')

load_fb_comment_count = ->
        $(".item").each ->
                slug = $(this).attr('rel')
                await $.get('https://api.facebook.com/method/fql.query',
                            {
                              query: "SELECT url,commentsbox_count FROM link_stat WHERE url='#{generate_url(slug)}'",
                              format: "json"
                            }
                            ,
                            (defer json),
                            "json")
                $(this).find(".commentcount").html(json[0].commentsbox_count)
        $("#items").isotope( 'updateSortData', $(".item") )

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
        should_show = should_show and ((selected_book == "") or (rec.book == selected_book)) and (not selected_slug)

        # the 'shown' class is applied to the relevant items
        $(".item[rel=#{slug}]").toggleClass("shown",should_show)

    setup_summary()

    if status_filter
        class_filter = [ ".shown.implementation-status-#{st}" for st in status_filter ]
        class_filter = class_filter.join(",")
    else
        class_filter = ".shown"

    class_filter = class_filter + ",.always-shown"

    # apply the filtering using Isotope
    $("#items").isotope({filter: class_filter});
    $("#items").isotope("reLayout");


## Load the current data for the site from google docs
load_data = ->
     $.get("/api",data_callback,"json")

## On document load
$ ->
   try
        await $.get("/api/version",(defer version),"json")
        current_version = localStorage.version
        localStorage.version = JSON.stringify(version)
        if current_version and version != JSON.parse(current_version)
                # Try to load data from the cache, to make the page load faster
                loaded_data = JSON.parse(localStorage.data)
                all_books = JSON.parse(localStorage.all_books)
                all_tags = JSON.parse(localStorage.all_tags)
                all_subjects = JSON.parse(localStorage.all_subjects)
                process_data()
         else
                load_data()
   catch error
        # If we don't succeed, load data immediately
        load_data()

