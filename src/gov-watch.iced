loaded_data = null
all_books = []
#all_chapters = {}
all_tags = []
all_people = []
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
go_to_comments = false

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

   if fullhash == "#about" || fullhash == "#partners"
        $("#container").css('display','none')
        $("#backlink").css('display','inline')
        $("#summary").html('')
        $("#summary-header").css('visibility','hidden')
        $("#orderstats").css('display','none')
        $("#searchwidget").css('display','none')
        $("#backlink").css('display','inline')
        $("#page").css('display','inherit')
        $("#page div").css('display','none')
        $("#page div#{fullhash}").css('display','inherit')
        return
   else
        $("#page").css('display','none')
        $("#container").css('display','inherit')
        $("#searchwidget").css('display','inherit')
        $("#orderstats").css('display','inherit')
        $("#summary-header").css('visibility','inherit')
        $("#backlink").css('display','none')

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
       $("#searchbox").val("סינון חופשי")
    else
        if wm_shown
            $("#searchbox").val("")
    wm_shown = show
    $("#searchbox").toggleClass('watermark',show)

convert_to_israeli_time = (reversed_time) ->
        if not reversed_time
                return "המועד לא הוגדר על ידי הוועדה"
        reversed_time = reversed_time.split(" ")
        if reversed_time.length > 1
                [date,time] = reversed_time
        else
                date = reversed_time[0]
                time = null
        date = date.split('/')
        if date[0] == '1970'
                return "המועד לא הוגדר על ידי הוועדה"
        date = "#{date[2]}/#{date[1]}/#{date[0]}"
        if time
                return "#{date} #{time}"
        else
                return date

## Handle initial loading of data, save it to Local Storage
data_callback = (data) ->
    loaded_data = data

    all_books = {}
    all_tags = {}
    all_people = {}
    all_subjects = {}

    # Collect all available books
    for rec in data
        num_links = {}
        if not all_books[rec.base.book]
            all_books[rec.base.book] = {}
        all_books[rec.base.book][rec.base.chapter] = true
        for tag in rec.base.tags
           all_tags[tag]=1
        if rec.base.responsible_authority?.main?
                all_people[rec.base.responsible_authority.main] = 1
        for t in rec.base.timeline
                t.israeli_due_date = convert_to_israeli_time(t.due_date)
        all_subjects[rec.base.subject]=1
        gov_updates = []
        watch_updates = []
        for k,v of rec.updates
                for u in v
                        u.user = k
                        u.israeli_update_time = convert_to_israeli_time(u.update_time)
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

        if rec.base.recommendation?.length > 400
                rec.base.recommendation_shortened = rec.base.recommendation[0..400] + "&nbsp;" +"<a class='goto-detail' rel='#{rec.slug}' href='#'>" + "עוד..." + "</a>"
        else
                rec.base.recommendation_shortened = rec.base.recommendation

        rec.base.budget.millions_text = "לא פורט על ידי הוועדה"
        if rec.base.budget?.millions?
                if rec.base.budget.millions > 0
                        rec.base.budget.millions_text = "#{rec.base.budget.millions} מיליון ₪"

        rec.base.budget.year_span_text = null
        if rec.base.budget?.year_span?
                if rec.base.budget.year_span > 0
                        rec.base.budget.year_span_text = rec.base.budget.year_span

    all_tags = Object.keys(all_tags)
    all_people = Object.keys(all_people)
    all_subjects = Object.keys(all_subjects)

    all_books = Object.keys(all_books)

    # Save to local storage if its available
    if localStorageEnabled()
        try
                localStorage.data = JSON.stringify(data)
                localStorage.all_books = JSON.stringify(all_books)
                localStorage.all_tags = JSON.stringify(all_tags)
                localStorage.all_people = JSON.stringify(all_people)
                localStorage.all_subjects=JSON.stringify(all_subjects)
        catch error
                console.log "failed to save to local storage "+error

    # process loaded data
    process_data()

localStorageEnabled = ->
    fail=uid=null
    try
       uid = "GOV-WATCH-canary"
       window.localStorage.setItem(uid, uid)
       fail = window.localStorage.getItem(uid) != uid
       window.localStorage.removeItem(uid)
       return fail
    catch e
        return false

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
       status_filter = null
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
    for person in all_people
        source.push({type:"person",title:person})
    for subject in all_subjects
        source.push({type:"subject",title:subject})
    $("#clearsearch").click ->
        search_term = ""
        show_watermark(true)
        status_filter = null
        update_history()
        return false
    $("#searchbox").typeahead
         source: source
         items: 20
         matcher: (item) -> ~item.title.indexOf(this.query)
         valueof: (item) -> item.title
         itemfrom: (query) -> {type:"subject", title:query}
         selected: (val) ->
                search_term = val
                status_filter = null
                update_history()
         highlighter: (item) ->
                highlighted_title = item.title.replace( new RegExp('(' + this.query + ')', 'ig'), ($1, match) -> '<strong>' + match + '</strong>' )
                if item.type == "subject"
                        return highlighted_title
                else if item.type == "tag"
                        "<span class='searchtag'><span>#{highlighted_title}</span></span>"
                else if item.type == "person"
                        "<span class='persontag'><span>#{highlighted_title}</span></span>"
                else
                        console.log item.type+" "+item.title

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

date_to_hebrew = (date) ->
        try
                date = date.split('/')
                [year,month,day] = (parseInt(d,10) for d in date)
        catch error
                return "לא הוגדר על ידי הוועדה"
        if isNaN(year) or isNaN(month)
                return "לא הוגדר על ידי הוועדה"
        month_to_hebrew = (month) ->
                switch month
                        when 1 then "ינואר"
                        when 2 then "פברואר"
                        when 3 then "מרץ"
                        when 4 then "אפריל"
                        when 5 then "מאי"
                        when 6 then "יוני"
                        when 7 then "יולי"
                        when 8 then "אוגוסט"
                        when 9 then "ספטמבר"
                        when 10 then "אוקטובר"
                        when 11 then "נובמבר"
                        when 12 then "דצמבר"
        return "#{month_to_hebrew(month)} #{year}"

# Numeric pad to %02d
pad = (n) -> if n<10 then '0'+n else n

# utility for timeline
status_to_hebrew = (status) ->
        switch status
                when "NEW" then return "טרם התחיל"
                when "STUCK" then return "תקוע"
                when "IN_PROGRESS" then return "בטיפול"
                when "FIXED" then return "יושם"
                when "WORKAROUND" then return "יושם חלקית"
                when "IRRELEVANT" then return "יישום ההמלצה כבר לא נדרש"
        return ""

status_tooltip_to_hebrew = (status) ->
        switch status
                when "NEW" then return "הממשלה החליטה שלא לטפל בהמלצה זו"
                when "STUCK" then return "ההמלצה בטיפול, אבל יש גורמים חיצוניים שמעכבים אותה"
                when "IN_PROGRESS" then return "ההמלצה נמצאת בטיפול. הסיבות לכך הן לרוב: חקיקה בכנסת, ועדות הדנות בנושא, או שההמלצה היא חלק מתוכנית חומש"
                when "FIXED" then return "מדד התפוקה יושם: הצעדים שהממשלה הייתה צריכה לעשות בוצעו"
                when "WORKAROUND" then return ""
                when "IRRELEVANT" then return ""
        return ""

is_good_status = (status) ->
        switch status
                when "NEW" then return false
                when "STUCK" then return false
                when "IN_PROGRESS" then return true
                when "FIXED" then return true
                when "WORKAROUND" then return false
                when "IRRELEVANT" then return true
        return null

setup_timeline_initial = (item_selector, margins=80 ) ->
    # Setup timeline after all elements have reached their required size
    item_selector.each ->

        horizontal = $(this).find('.timeline-logic.horizontal').size() > 0

        slug = $(this).attr('rel')

        # Get today's date
        today = new Date()
        today = "#{today.getFullYear()}/#{pad(today.getMonth()+1)}/#{pad(today.getDate()+1)}"

        # Process dates & convert to numeric
        max_numeric_date = 0
        min_numeric_date = 2100 * 372
        $(this).find('.timeline-logic .timeline-point.today').attr('data-date',today)

        has_unknowns = false
        $(this).find(".timeline-logic > ul > li").each( ->
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
                $(this).find('.timeline-point').attr('data-date-numeric',numeric_date)
        )

        # If some milestones are unknown, assume last milestone is in 6 months
        if has_unknowns
                max_numeric_date += 180
                $(this).find(".timeline-logic > ul > li[data-date-numeric='xxx']").attr('data-date-numeric',max_numeric_date)
                $(this).find(".timeline-logic > ul > li[data-date-numeric='xxx']").find('.timeline-point').attr('data-date-numeric',max_numeric_date)

        $(this).find(".timeline-logic").attr('data-max-numeric-date',max_numeric_date)
        $(this).find(".timeline-logic").attr('data-min-numeric-date',min_numeric_date)

        if not horizontal
                initial_year = (Math.ceil(min_numeric_date/372.0)).toFixed(0)
                last_year = (Math.floor(max_numeric_date/372.0)).toFixed(0)
                for y in [initial_year..last_year]
                        numeric = y*372
                        $(this).find(".timeline-logic > ul").append("
                                <li data-date-numeric='#{numeric}'>
                                        <div class='timeline-line'></div>
                                        <div class='timeline-point milestone tick' data-date-numeric='#{numeric}' data-date='#{y}/01/01'><div>#{y}</div></div>
                                </li>")

        # Sort by timestamp
        $(this).find(".update-feed > ul > li").tsort({attr:'data-date',order:'desc'})
        $(this).find(".timeline-logic > ul > li").tsort({attr:'data-date-numeric',order:'desc'})

        # initial government status and related variables
        gov_status = 'NEW'
        conflict = false
        conflict_status = null
        late = false

        timeline_items = $(this).find(".timeline-logic > ul > li")

        # check lateness (= no gov update in the last 6 months)
        today_date = parseInt($(this).find(".timeline-logic > ul > li .today").attr('data-date-numeric'))
        last_update = $(this).find(".timeline-logic > ul > li .gov-update:first").attr('data-date-numeric')
        if last_update
                last_update = parseInt(last_update)
        else
                last_update = min_numeric_date
        if last_update and today_date
                if today_date - last_update > 180
                        late = true

        # iterate over items and calculate status
        NOT_SET = 1000
        last_update_at = NOT_SET
        today_at = NOT_SET
        fixed_at = NOT_SET

        for i in [timeline_items.size()-1..0]
                el = $(timeline_items[i])
                point = el.find('.timeline-point:first')
                line = el.find('.timeline-line:first')

                # current point's implementation-status (or the gov's status if not available)
                status = point.attr('data-status') ? gov_status

                # gov updates remove conflicts
                if point.hasClass('gov-update')
                        conflict_status = null
                        gov_status = status ? gov_status
                        last_update_at = i

                        # when was it fixed?
                        if (fixed_at == NOT_SET) and (gov_status == "FIXED" or gov_status == "IRRELEVANT")
                                fixed_at = i

                        # set css classes accordingly
                        point.addClass("gov-#{gov_status}")
                        if is_good_status(gov_status)
                                point.addClass("gov-status-good")
                        else
                                point.addClass("gov-status-bad")

                # handle today points
                its_today = false
                if point.hasClass("today")
                        today_at = i
                        its_today = true

                # handle watch updates
                if point.hasClass('watch-update')
                        if is_good_status(status) != null
                                conflict_status = status
                                point.addClass("watch-#{status}")
                                if is_good_status(status)
                                        point.addClass("watch-status-good")
                                else
                                        point.addClass("watch-status-bad")
                        else
                                point.addClass("no-review")
                                point.removeClass("update")
                        last_update_at = i

                # for all points up till today (including)
                if today_at == NOT_SET or its_today
                        # set implementation status to the correct one
                        el.find('.implementation-status').addClass("label-#{status}")
                        el.find('.implementation-status').html(status_to_hebrew(status))

                        # set gov-status to the line (this is the line AFTER the point)
                        line.addClass("status-#{gov_status}")

                        # set conflict if needed
                        #if conflict
                        #        point.addClass("conflict")

        # Fix line styles between today, last update, and set classes accordingly
        for i in [timeline_items.size()-1..0]
                el = $(timeline_items[i])
                line = el.find('.timeline-line:first')

                #if (fixed_at != NOT_SET and i <= fixed_at) or i <= today_at
                if i <= today_at
                        line.addClass("future")
                else
                        line.addClass("past")
                        if i <= last_update_at
                                line.addClass("unreported")

        # current implementation status for buxa
        implementation_status = gov_status
        if implementation_status != "FIXED" and implementation_status != "IRRELEVANT" and implementation_status != "NEW"
                if late
                        implementation_status = "STUCK"
        else
                late = false

        if conflict_status
                if is_good_status(implementation_status) != is_good_status(conflict_status)
                        conflict = true

        buxa_header = $(this).find('.buxa-header')
        if conflict
                buxa_header.addClass('conflict')
        else
                buxa_header.removeClass('conflict')
                if is_good_status( implementation_status )
                     buxa_header.addClass('good')
                else
                     buxa_header.addClass('bad')

        if conflict
                $(this).attr('data-implementation-status',"CONFLICT")
                $(this).addClass("implementation-status-CONFLICT")
        else
                $(this).attr('data-implementation-status',implementation_status)
                $(this).addClass("implementation-status-#{implementation_status}")

        if is_good_status(implementation_status)
                $(this).addClass("implementation-status-good")
        else
                $(this).addClass("implementation-status-bad")

        # buxa stamps
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
        stamp_tooltip = status_tooltip_to_hebrew(implementation_status)
        buxa_header.before("<div class='stamp #{stamp_class}' title='#{stamp_tooltip}'></div>")

        if conflict
                stamp = status_to_hebrew(conflict_status)
                stamp_class = status_to_stamp_class(conflict_status)
                stamp_tooltip = status_tooltip_to_hebrew(conflict_status)
                buxa_header.before("<div class='stamp conflicting #{stamp_class}'  title='#{stamp_tooltip}'></div>")

setup_timeline_visual = (item_selector, margins=80 ) ->

    # Setup timeline after all elements have reached their required size
    item_selector.each ->

        horizontal = $(this).find('.timeline-logic.horizontal').size() > 0

        # Process dates & convert to numeric
        max_numeric_date = parseInt($(this).find('.timeline-logic').attr('data-max-numeric-date'))
        min_numeric_date = parseInt($(this).find('.timeline-logic').attr('data-min-numeric-date'))

        # profile image
        $(this).find('img').each ->
                alt = $(this).attr('alt')
                if alt
                        $(this).attr('src',"/profile/#{slugify(alt)}")

        # Finish date handling
        finish_date = $(this).find(".timeline-logic > ul > li > .milestone:first").attr('data-date')
        finish_date = date_to_hebrew(finish_date)
        $(this).find(".duedate > p").html(finish_date)

        # Calculate widths and issue's status
        # ---------

        # All kinds of measurements
        last_percent = 0.0
        item_margins = 5
        if horizontal
                size = $(this).innerWidth() - margins
        else
                size = $(this).innerHeight() - margins
        available_size = size
        $(this).find(".timeline-logic > ul > li .timeline-point").each( ->
                if horizontal
                        available_size = available_size - $(this).outerWidth() - item_margins
                else
                        available_size = available_size - $(this).outerHeight() - item_margins
                )
        margin = 0

        # iterate over items and set size
        $(this).find(".timeline-logic > ul > li").each( ->
                point = $(this).find('.timeline-point:first')
                line = $(this).find('.timeline-line:first')

                date = parseInt($(this).attr('data-date-numeric'))

                percent = (max_numeric_date - date) / (max_numeric_date - min_numeric_date)
                if horizontal
                        point_size = point.outerWidth() + item_margins
                else
                        point_size = point.outerHeight() + item_margins

                item_size = available_size * (percent - last_percent) + point_size
                if horizontal
                        $(this).css('width',item_size)
                        $(this).css('left',margin)
                else
                        $(this).css('height',item_size)
                        $(this).css('top',margin)

                last_percent = percent
                margin = margin + item_size
        )

        # remove first line (which appears AFTER the last milestone / point)
        $(this).find(".timeline-logic > ul > li:first > .timeline-line").remove()

setup_summary = ->
        total = $(".item.shown").size()
        stuck = $(".item.shown[data-implementation-status='STUCK']").size()
        news = $(".item.shown[data-implementation-status='NEW']").size()
        in_progress = $(".item.shown[data-implementation-status='IN_PROGRESS']").size()
        fixed = $(".item.shown[data-implementation-status='FIXED']").size()
        workaround = $(".item.shown[data-implementation-status='WORKAROUND']").size()
        irrelevant = $(".item.shown[data-implementation-status='IRRELEVANT']").size()
        conflict = $(".item.shown[data-implementation-status='CONFLICT']").size()
        data = {}
        if total
                data.total = total
        if news
                data.news = news
        stuck = workaround + stuck
        if stuck
                data.stuck = stuck
        implemented = fixed + irrelevant
        if implemented
                data.implemented = implemented
        if in_progress
                data.in_progress = in_progress
        if conflict
                data.conflict = conflict
        $("#summary").html('')
        run_templates( "summary", data, "#summary" )
        setup_tooltips($("#summary"))

        $("#summary .total").click ->
                status_filter = null
                do_search()
                return false
        $("#summary .news").click ->
                status_filter = ['NEW']
                do_search()
                return false
        $("#summary .stuck").click ->
                status_filter = ['STUCK','WORKAROUND']
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
        $("#summary .conflict").click ->
                status_filter = ['CONFLICT']
                do_search()
                return false

setup_subscription_form = ->
   $("#subscribe").modal({'show':false})
   $("#do_subscribe").click ->
        $("#subscribe_form").submit()
        return false
   $("#subscribe_form").submit ->
        $.post($(this).attr('action'),
               'email':$("#subscribe_email").val(),
                (data) =>
                        $("#subscribe").modal('hide')
                        rel = $(this).attr("rel")
                        $(".watch[rel='#{rel}']").html(data)
                 ,
                "json"
                )
        return false

setup_subscriptions = (selector) ->
        selector.find(".watch").click ->
                rel = $(this).attr('rel')
                $("#subscribe_email").attr('data-slug',rel)
                $("#subscribe_form").attr('action',"/subscribe/#{rel}")
                $("#subscribe_form").attr('rel',rel)
                $("#subscribe").modal('show')
                return false


setup_tags = (selector) ->
   $(selector).click ->
        search_term = $(this).text()
        show_watermark(false)
        $("#searchbox").val(search_term)
        $("#explanation").modal('hide')
        status_filter = null
        update_history()
        return false

setup_detailed_links = ->
    $(".item .goto-detail"). click ->
        if $(this).hasClass("commentcount")
                go_to_comments = true
        rel = $(this).attr('rel')
        if not rel
                for p in $(this).parents()
                        rel = $(p).attr('rel')
                        if rel
                                break
        update_history(rel)
        return false

setup_tooltips = (selector) ->
        $("div.tooltip").remove()
        selector.find(".rel-tooltip").tooltip({placement:'bottom'})

## Handles the site's data (could be from local storage or freshly loaded)
process_data = ->

    # process only once
    if initialized
       return
    initialized = true

    # Fill contents to the book selection sidebox
    for book in all_books
        $("#books").prepend("<li data-book='#{book}' class='book'><a href='#'>#{book}</a></li>")

    await $.get('/api/fb',null,(defer cc),"json")
    for i in [0..loaded_data.length-1]
        rec = loaded_data[i]
        slug = rec.slug
        if cc? && cc[slug]?
                loaded_data[i].base.fbcomments = cc[slug]

    run_templates( "item", items: loaded_data, "#items" )

    # Explanation unit
    explanation_needed = true
    if localStorageEnabled() and localStorage.explained?
        explanation_needed = false

    $("#explanation .close").click ->
        if localStorageEnabled()
            localStorage.explained = true
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
        animationEngine: "css"
        getSortData :
           followers:  ( e ) -> -parseInt( "0"+e.find('.watch').text() )
           original :  ( e ) -> "#{e.attr('data-chapter')}/#{e.attr('data-subchapter')}/#{e.attr('rel')}"
           budget :  ( e ) ->
                        -parseInt( "0"+e.attr('cost'), 10 )
           comments :  ( e ) ->
                          ret = -parseInt( "0"+e.find('.commentcount').text(), 10 )
                          return ret
    )

    # Let isotope do its magic
    await setTimeout((defer _),50)

    setup_subscription_form()
    setup_searchbox()
    setup_tags(".item .tags > ul > li, a[data-tag='true'], .searchtag > span")
    setup_detailed_links()

    $(".item").one('inview', ->
            setup_timeline_visual($(this))
            $(this).css('visibility','inherit')
            setup_subscriptions($(this))
            setup_tooltips($(this))
        )

    setup_timeline_initial($(".item"))

    # book selection
    $("#books li.book a").click ->
        selected_book = $(this).html()
        update_history()
        return false

    # sort buttons
    $("#sort button").click ->
        $("#sort button").removeClass('active')
        $(this).addClass('active')
        sort_measure = $(this).attr('value')
        $("#items").isotope( 'updateSortData', $(".isotope-card") )
        $("#items").isotope({ sortBy: sort_measure })
        return false

    # item click handler
    # $(".item").click -> update_history($(this).attr('rel'))

    $("#explanation").modal({'show':explanation_needed})

    # handle hash change events, and process current (initial) hash
    window.onhashchange = onhashchange
    onhashchange()
    # Wait a second before loading FB comment counts
    await setTimeout((defer _),1000)

## Item selection
select_item = (slug) ->
    $('fb\\:comments').remove()
    $('fb\\:like').remove()
    if slug
        $("#summary").html('')
        $("#summary-header").css('visibility','hidden')
        $("#orderstats").css('display','none')
        $("#searchwidget").css('display','none')
        $("#backlink").css('display','inline')
        $("#sort button").addClass('disabled')
        $("#clearsearch").addClass('disabled')
        $("#clearsearch").attr('disabled','disabled')
        for x in loaded_data
                if x.slug == slug
                        item = run_templates( "single-item", x, "#single-item" )
                        set_title( x.base.book+": "+x.base.subject )
                        url = generate_url(slug)
                        $(".detail-view .fb").append("<fb:like href='#{url}' send='true' width='700' show_faces='true' action='recommend' font='tahoma'></fb:like>")
                        $(".detail-view .fb").append("<fb:comments href='#{url}' num_posts='2' width='700'></fb:comments>")
                        if window.FB
                           FB.XFBML.parse( item.get(0), -> )
                           window.updateFB = ->
                        else
                           window.updateFB = ->
                                FB.XFBML.parse( item.get(0), -> )
                        break
        # Allow DOM to sync
        await setTimeout((defer _),50)
        setup_timeline_initial($('.detail-view'),69)
        setup_timeline_visual($('.detail-view'),69)
        setup_subscriptions($(".detail-view"))
        setup_tags(".detail-view .tags > ul > li")
        setup_tooltips($(".detail-view"))
        $("#single-item .commentcount").click ->
                $('html, body').animate({ scrollTop: $("#single-item .fb").offset().top }, 0)
                return false
        $("#single-item .linkcount").click ->
                $('html, body').animate({ scrollTop: $("#single-item .timeline").offset().top }, 0)
                return false
        if go_to_comments
                scroll_to = $(".fb").offset().top - 300
        else
                scroll_to = 0
        go_to_comments = false
        $('html, body').animate({ scrollTop: scroll_to }, 0)
    else
        $("#single-item").html('')
        $("#sort button").removeClass('disabled')
        $("#searchwidget").css('display','inherit')
        $("#orderstats").css('display','inherit')
        $("#summary-header").css('visibility','inherit')
        $("#backlink").css('display','none')
        $("#clearsearch").removeClass('disabled')
        $("#clearsearch").attr('disabled',null)


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
        try
                current_version = localStorage.version
                if current_version and version == JSON.parse(current_version)
                        # Try to load data from the cache, to make the page load faster
                        loaded_data = JSON.parse(localStorage.data)
                        all_books = JSON.parse(localStorage.all_books)
                        all_tags = JSON.parse(localStorage.all_tags)
                        all_people = JSON.parse(localStorage.all_people)
                        all_subjects = JSON.parse(localStorage.all_subjects)
                        process_data()
                        localStorage.version = JSON.stringify(version)
                 else
                        console.log "wrong version "+current_version+" != "+version
                        load_data()
                        localStorage.version = JSON.stringify(version)
        catch error
                console.log "failed to load data from storage: " + error
                load_data()
   catch error
        # If we don't succeed, load data immediately
        load_data()

