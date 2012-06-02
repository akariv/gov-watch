/*
  mustache.js — Logic-less templates in JavaScript

  See http://mustache.github.com/ for more info.
*/

var Mustache = function() {
  var regexCache = {};
  var Renderer = function() {};

  Renderer.prototype = {
    otag: "{{",
    ctag: "}}",
    pragmas: {},
    buffer: [],
    pragmas_implemented: {
      "IMPLICIT-ITERATOR": true
    },
    context: {},

    render: function(template, context, partials, in_recursion) {
      // reset buffer & set context
      if(!in_recursion) {
        this.context = context;
        this.buffer = []; // TODO: make this non-lazy
      }

      // fail fast
      if(!this.includes("", template)) {
        if(in_recursion) {
          return template;
        } else {
          this.send(template);
          return;
        }
      }

      // get the pragmas together
      template = this.render_pragmas(template);

      // render the template
      var html = this.render_section(template, context, partials);

      // render_section did not find any sections, we still need to render the tags
      if (html === false) {
        html = this.render_tags(template, context, partials, in_recursion);
      }

      if (in_recursion) {
        return html;
      } else {
        this.sendLines(html);
      }
    },

    /*
      Sends parsed lines
    */
    send: function(line) {
      if(line !== "") {
        this.buffer.push(line);
      }
    },

    sendLines: function(text) {
      if (text) {
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
          this.send(lines[i]);
        }
      }
    },

    /*
      Looks for %PRAGMAS
    */
    render_pragmas: function(template) {
      // no pragmas
      if(!this.includes("%", template)) {
        return template;
      }

      var that = this;
      var regex = this.getCachedRegex("render_pragmas", function(otag, ctag) {
        return new RegExp(otag + "%([\\w-]+) ?([\\w]+=[\\w]+)?" + ctag, "g");
      });

      return template.replace(regex, function(match, pragma, options) {
        if(!that.pragmas_implemented[pragma]) {
          throw({message:
            "This implementation of mustache doesn't understand the '" +
            pragma + "' pragma"});
        }
        that.pragmas[pragma] = {};
        if(options) {
          var opts = options.split("=");
          that.pragmas[pragma][opts[0]] = opts[1];
        }
        return "";
        // ignore unknown pragmas silently
      });
    },

    /*
      Tries to find a partial in the curent scope and render it
    */
    render_partial: function(name, context, partials) {
      name = this.trim(name);
      if(!partials || partials[name] === undefined) {
        throw({message: "unknown_partial '" + name + "'"});
      }
      if(typeof(context[name]) != "object") {
        return this.render(partials[name], context, partials, true);
      }
      return this.render(partials[name], context[name], partials, true);
    },

    /*
      Renders inverted (^) and normal (#) sections
    */
    render_section: function(template, context, partials) {
      if(!this.includes("#", template) && !this.includes("^", template)) {
        // did not render anything, there were no sections
        return false;
      }

      var that = this;

      var regex = this.getCachedRegex("render_section", function(otag, ctag) {
        // This regex matches _the first_ section ({{#foo}}{{/foo}}), and captures the remainder
        return new RegExp(
          "^([\\s\\S]*?)" +         // all the crap at the beginning that is not {{*}} ($1)

          otag +                    // {{
          "(\\^|\\#)\\s*(.+)\\s*" + //  #foo (# == $2, foo == $3)
          ctag +                    // }}

          "\n*([\\s\\S]*?)" +       // between the tag ($2). leading newlines are dropped

          otag +                    // {{
          "\\/\\s*\\3\\s*" +        //  /foo (backreference to the opening tag).
          ctag +                    // }}

          "\\s*([\\s\\S]*)$",       // everything else in the string ($4). leading whitespace is dropped.

        "g");
      });


      // for each {{#foo}}{{/foo}} section do...
      return template.replace(regex, function(match, before, type, name, content, after) {
        // before contains only tags, no sections
        var renderedBefore = before ? that.render_tags(before, context, partials, true) : "",

        // after may contain both sections and tags, so use full rendering function
            renderedAfter = after ? that.render(after, context, partials, true) : "",

        // will be computed below
            renderedContent,

            value = that.find(name, context);

        if (type === "^") { // inverted section
          if (!value || that.is_array(value) && value.length === 0) {
            // false or empty list, render it
            renderedContent = that.render(content, context, partials, true);
          } else {
            renderedContent = "";
          }
        } else if (type === "#") { // normal section
          if (that.is_array(value)) { // Enumerable, Let's loop!
            renderedContent = that.map(value, function(row) {
              return that.render(content, that.create_context(row), partials, true);
            }).join("");
          } else if (that.is_object(value)) { // Object, Use it as subcontext!
            renderedContent = that.render(content, that.create_context(value),
              partials, true);
          } else if (typeof value === "function") {
            // higher order section
            renderedContent = value.call(context, content, function(text) {
              return that.render(text, context, partials, true);
            });
          } else if (value) { // boolean section
            renderedContent = that.render(content, context, partials, true);
          } else {
            renderedContent = "";
          }
        }

        return renderedBefore + renderedContent + renderedAfter;
      });
    },

    /*
      Replace {{foo}} and friends with values from our view
    */
    render_tags: function(template, context, partials, in_recursion) {
      // tit for tat
      var that = this;



      var new_regex = function() {
        return that.getCachedRegex("render_tags", function(otag, ctag) {
          return new RegExp(otag + "(=|!|>|\\{|%)?([^\\/#\\^]+?)\\1?" + ctag + "+", "g");
        });
      };

      var regex = new_regex();
      var tag_replace_callback = function(match, operator, name) {
        switch(operator) {
        case "!": // ignore comments
          return "";
        case "=": // set new delimiters, rebuild the replace regexp
          that.set_delimiters(name);
          regex = new_regex();
          return "";
        case ">": // render partial
          return that.render_partial(name, context, partials);
        case "{": // the triple mustache is unescaped
          return that.find(name, context);
        default: // escape the value
          return that.escape(that.find(name, context));
        }
      };
      var lines = template.split("\n");
      for(var i = 0; i < lines.length; i++) {
        lines[i] = lines[i].replace(regex, tag_replace_callback, this);
        if(!in_recursion) {
          this.send(lines[i]);
        }
      }

      if(in_recursion) {
        return lines.join("\n");
      }
    },

    set_delimiters: function(delimiters) {
      var dels = delimiters.split(" ");
      this.otag = this.escape_regex(dels[0]);
      this.ctag = this.escape_regex(dels[1]);
    },

    escape_regex: function(text) {
      // thank you Simon Willison
      if(!arguments.callee.sRE) {
        var specials = [
          '/', '.', '*', '+', '?', '|',
          '(', ')', '[', ']', '{', '}', '\\'
        ];
        arguments.callee.sRE = new RegExp(
          '(\\' + specials.join('|\\') + ')', 'g'
        );
      }
      return text.replace(arguments.callee.sRE, '\\$1');
    },

    /*
      find `name` in current `context`. That is find me a value
      from the view object
    */
    find: function(name, context) {
      name = this.trim(name);

      // Checks whether a value is thruthy or false or 0
      function is_kinda_truthy(bool) {
        return bool === false || bool === 0 || bool;
      }

      var value;
      if(is_kinda_truthy(context[name])) {
        value = context[name];
      } else if(is_kinda_truthy(this.context[name])) {
        value = this.context[name];
      }

      if(typeof value === "function") {
        return value.apply(context);
      }
      if(value !== undefined) {
        return value;
      }
      // silently ignore unkown variables
      return "";
    },

    // Utility methods

    /* includes tag */
    includes: function(needle, haystack) {
      return haystack.indexOf(this.otag + needle) != -1;
    },

    /*
      Does away with nasty characters
    */
    escape: function(s) {
      s = String(s === null ? "" : s);
      return s.replace(/&(?!\w+;)|["'<>\\]/g, function(s) {
        switch(s) {
        case "&": return "&amp;";        
        case '"': return '&quot;';
        case "'": return '&#39;';
        case "<": return "&lt;";
        case ">": return "&gt;";
        default: return s;
        }
      });
    },

    // by @langalex, support for arrays of strings
    create_context: function(_context) {
      if(this.is_object(_context)) {
        return _context;
      } else {
        var iterator = ".";
        if(this.pragmas["IMPLICIT-ITERATOR"]) {
          iterator = this.pragmas["IMPLICIT-ITERATOR"].iterator;
        }
        var ctx = {};
        ctx[iterator] = _context;
        return ctx;
      }
    },

    is_object: function(a) {
      return a && typeof a == "object";
    },

    is_array: function(a) {
      return Object.prototype.toString.call(a) === '[object Array]';
    },

    /*
      Gets rid of leading and trailing whitespace
    */
    trim: function(s) {
      return s.replace(/^\s*|\s*$/g, "");
    },

    /*
      Why, why, why? Because IE. Cry, cry cry.
    */
    map: function(array, fn) {
      if (typeof array.map == "function") {
        return array.map(fn);
      } else {
        var r = [];
        var l = array.length;
        for(var i = 0; i < l; i++) {
          r.push(fn(array[i]));
        }
        return r;
      }
    },

    getCachedRegex: function(name, generator) {
      var byOtag = regexCache[this.otag];
      if (!byOtag) {
        byOtag = regexCache[this.otag] = {};
      }

      var byCtag = byOtag[this.ctag];
      if (!byCtag) {
        byCtag = byOtag[this.ctag] = {};
      }

      var regex = byCtag[name];
      if (!regex) {
        regex = byCtag[name] = generator(this.otag, this.ctag);
      }

      return regex;
    }
  };

  return({
    name: "mustache.js",
    version: "0.4.0-dev",

    /*
      Turns a template and view into HTML
    */
    to_html: function(template, view, partials, send_fun) {
      var renderer = new Renderer();
      if(send_fun) {
        renderer.send = send_fun;
      }
      renderer.render(template, view || {}, partials);
      if(!send_fun) {
        return renderer.buffer.join("\n");
      }
    }
  });
}();
// Generated by IcedCoffeeScript 1.2.0s
(function() {
  var BOOK, SEARCHTERM, SLUG, all_books, all_subjects, all_tags, data_callback, do_search, generate_hash, generate_url, iced, initialized, load_data, load_fb_comment_count, loaded_data, onhashchange, process_data, run_templates, search_term, select_item, selected_book, selected_slug, set_title, setup_searchbox, setup_subscriptions, setup_summary, setup_tags, setup_timeline, show_watermark, skip_overview, slugify, status_filter, unslugify, update_history, wm_shown, __iced_k_noop,
    __slice = [].slice;

  iced = {
    Deferrals: (function() {

      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
        this.ret = null;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) return this.continuation(this.ret);
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })(),
    findDeferral: function() {
      return null;
    }
  };
  __iced_k_noop = function() {};

  loaded_data = null;

  all_books = [];

  all_tags = [];

  all_subjects = [];

  selected_book = "";

  search_term = "";

  selected_slug = "";

  skip_overview = false;

  BOOK = 'b';

  SLUG = 's';

  SEARCHTERM = 't';

  status_filter = null;

  slugify = function(str) {
    var ch, co, str2, x, _i, _ref;
    str2 = "";
    if (str === "") return "";
    for (x = _i = 0, _ref = str.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
      ch = str.charAt(x);
      co = str.charCodeAt(x);
      if (co >= 0x5d0 && co < 0x600) co = co - 0x550;
      if (co < 256) str2 += (co + 0x100).toString(16).substr(-2).toUpperCase();
    }
    return str2;
  };

  unslugify = function(str) {
    var ch, str2, x, _i, _ref;
    str2 = "";
    if (str === "") return "";
    for (x = _i = 0, _ref = (str.length / 2) - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
      ch = str.slice(x * 2, (x * 2 + 1) + 1 || 9e9);
      ch = parseInt(ch, 16);
      if (ch >= 128) ch += 0x550;
      str2 = str2 + String.fromCharCode(ch);
    }
    return str2;
  };

  generate_hash = function(selected_book, search_term, slug) {
    if (slug) {
      return "!z=" + BOOK + ":" + (slugify(selected_book)) + "_" + SLUG + ":" + slug;
    } else {
      return "!z=" + BOOK + ":" + (slugify(selected_book)) + "_" + SEARCHTERM + ":" + (slugify(search_term));
    }
  };

  generate_url = function(slug) {
    return "http://" + window.location.host + "/#" + (generate_hash(selected_book, "", slug));
  };

  update_history = function(slug) {
    var ___iced_passed_deferral, __iced_deferrals, __iced_k,
      _this = this;
    __iced_k = __iced_k_noop;
    ___iced_passed_deferral = iced.findDeferral(arguments);
    (function(__iced_k) {
      __iced_deferrals = new iced.Deferrals(__iced_k, {
        parent: ___iced_passed_deferral,
        filename: "gov-watch.iced",
        funcname: "update_history"
      });
      setTimeout((__iced_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return __iced_deferrals.ret = arguments[0];
          };
        })(),
        lineno: 56
      })), 0);
      __iced_deferrals._fulfill();
    })(function() {
      return window.location.hash = generate_hash(selected_book, search_term, slug);
    });
  };

  set_title = function(title) {
    return $("title").html(title);
  };

  onhashchange = function() {
    var fullhash, hash, key, part, slug, splits, value, _i, _len, _ref;
    fullhash = window.location.hash;
    hash = fullhash.slice(4, fullhash.length);
    splits = hash.split("_");
    slug = null;
    selected_book = null;
    search_term = "";
    for (_i = 0, _len = splits.length; _i < _len; _i++) {
      part = splits[_i];
      _ref = part.split(":"), key = _ref[0], value = _ref[1];
      if (key === BOOK) selected_book = unslugify(value);
      if (key === SLUG) slug = value;
      if (key === SEARCHTERM) search_term = unslugify(value);
    }
    if (!selected_book && !slug) {
      selected_book = all_books[0];
      update_history();
      return;
    }
    $("#books li.book").toggleClass('active', false);
    $("#books li.book[data-book='" + selected_book + "']").toggleClass('active', true);
    if (search_term !== "") {
      show_watermark(false);
      $("#searchbox").val(search_term);
    }
    if (slug) {
      selected_slug = slug;
      select_item(selected_slug);
      $(".item").removeClass("shown");
      $("#items").isotope({
        filter: ".shown"
      });
    } else {
      set_title('דו"ח טרכטנברג | המפקח: מעקב אחר ישום המלצות הועדה');
      selected_slug = null;
      select_item(null);
      do_search();
    }
    return _gaq.push(['_trackPageview', '/'+fullhash]);;
  };

  wm_shown = false;

  show_watermark = function(show) {
    if (show) {
      $("#searchbox").val("סינון חופשי של ההמלצות");
    } else {
      if (wm_shown) $("#searchbox").val("");
    }
    wm_shown = show;
    return $("#searchbox").toggleClass('watermark', show);
  };

  data_callback = function(data) {
    var gov_updates, k, l, num_links, rec, tag, u, v, watch_updates, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _ref4, _ref5;
    loaded_data = data;
    all_books = {};
    all_tags = {};
    all_subjects = {};
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      rec = data[_i];
      num_links = {};
      if (!all_books[rec.base.book]) all_books[rec.base.book] = {};
      all_books[rec.base.book][rec.base.chapter] = true;
      _ref = rec.base.tags;
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        tag = _ref[_j];
        all_tags[tag] = 1;
      }
      all_subjects[rec.base.subject] = 1;
      gov_updates = [];
      watch_updates = [];
      _ref2 = rec.updates;
      for (k in _ref2) {
        v = _ref2[k];
        for (_k = 0, _len3 = v.length; _k < _len3; _k++) {
          u = v[_k];
          u.user = k;
          if (k === 'gov') {
            gov_updates.push(u);
          } else {
            watch_updates.push(u);
          }
          if (u.links) {
            _ref3 = u.links;
            for (_l = 0, _len4 = _ref3.length; _l < _len4; _l++) {
              l = _ref3[_l];
              num_links[l.url] = true;
            }
          }
        }
      }
      rec.base.num_links = Object.keys(num_links).length;
      rec.gov_updates = gov_updates;
      rec.watch_updates = watch_updates;
      rec.base.subscribers = (_ref4 = rec.subscribers) != null ? _ref4 : 0;
      if (((_ref5 = rec.base.recommendation) != null ? _ref5.length : void 0) > 500) {
        rec.base.recommendation_shortened = rec.base.recommendation.slice(0, 501) + "&nbsp;" + ("<a href='" + (generate_url(rec.slug)) + "'>") + "עוד..." + "</a>";
      } else {
        rec.base.recommendation_shortened = rec.base.recommendation;
      }
    }
    all_tags = Object.keys(all_tags);
    all_subjects = Object.keys(all_subjects);
    all_books = Object.keys(all_books);
    if (localStorage) {
      localStorage.data = JSON.stringify(data);
      localStorage.all_books = JSON.stringify(all_books);
      localStorage.all_tags = JSON.stringify(all_tags);
      localStorage.all_subjects = JSON.stringify(all_subjects);
    }
    return process_data();
  };

  initialized = false;

  setup_searchbox = function() {
    var source, subject, tag, _i, _j, _len, _len2;
    show_watermark(true);
    $("#searchbox").change(function() {
      if (wm_shown) {
        search_term = "";
      } else {
        search_term = $("#searchbox").val();
      }
      return update_history();
    });
    $("#searchbox").focus(function() {
      return show_watermark(false);
    });
    $("#searchbox").blur(function() {
      if ($(this).val() === "") return show_watermark(true);
    });
    $("#searchbar").submit(function() {
      return false;
    });
    source = [];
    for (_i = 0, _len = all_tags.length; _i < _len; _i++) {
      tag = all_tags[_i];
      source.push({
        type: "tag",
        title: tag
      });
    }
    for (_j = 0, _len2 = all_subjects.length; _j < _len2; _j++) {
      subject = all_subjects[_j];
      source.push({
        type: "subject",
        title: subject
      });
    }
    $("#searchbox").typeahead({
      source: source,
      items: 20,
      matcher: function(item) {
        return ~item.title.indexOf(this.query);
      },
      valueof: function(item) {
        return item.title;
      },
      itemfrom: function(query) {
        return {
          type: "subject",
          title: query
        };
      },
      selected: function(val) {
        search_term = val;
        return update_history();
      },
      highlighter: function(item) {
        var highlighted_title;
        highlighted_title = item.title.replace(new RegExp('(' + this.query + ')', 'ig'), function($1, match) {
          return '<strong>' + match + '</strong>';
        });
        if (item.type === "subject") return highlighted_title;
        if (item.type === "tag") {
          return "<span class='searchtag'><span>" + highlighted_title + "</span></span>";
        }
      }
    });
    return $("#clearsearch").click(function() {
      search_term = "";
      show_watermark(true);
      return update_history();
    });
  };

  run_templates = function(template, data, selector) {
    var html;
    template = $("script[name=" + template + "]").html();
    html = Mustache.to_html(template, data);
    return $(selector).html(html);
  };

  setup_timeline = function() {
    return $(".item").each(function() {
      var NOT_SET, available_height, conflict, conflict_status, el, fixed_at, gov_status, has_unknowns, height, i, implementation_status, is_good_status, item_margins, its_today, last_percent, last_update, last_update_at, late, line, margins, max_numeric_date, min_numeric_date, pad, point, stamp, stamp_class, status, status_to_hebrew, status_to_stamp_class, timeline_items, today, today_at, today_date, top, _i, _j, _ref, _ref2, _ref3, _ref4;
      pad = function(n) {
        if (n < 10) {
          return '0' + n;
        } else {
          return n;
        }
      };
      today = new Date();
      today = "" + (today.getFullYear()) + "/" + (pad(today.getMonth() + 1)) + "/" + (pad(today.getDate() + 1));
      max_numeric_date = 0;
      min_numeric_date = 2100 * 372;
      $(this).find('.timeline .timeline-point.today').attr('data-date', today);
      has_unknowns = false;
      $(this).find(".timeline > ul > li").each(function() {
        var alt, d, date, day, hour, img, min, month, numeric_date, second, t, time, year, _ref, _ref2;
        date = $(this).find('.timeline-point:first').attr('data-date');
        date = date.split(' ');
        if (date.length > 1) {
          time = date[1];
        } else {
          time = "00:00:00";
        }
        date = date[0].split('/');
        time = time.split(':');
        _ref = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = date.length; _i < _len; _i++) {
            d = date[_i];
            _results.push(parseInt(d, 10));
          }
          return _results;
        })(), year = _ref[0], month = _ref[1], day = _ref[2];
        _ref2 = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = time.length; _i < _len; _i++) {
            t = time[_i];
            _results.push(parseInt(t, 10));
          }
          return _results;
        })(), hour = _ref2[0], min = _ref2[1], second = _ref2[2];
        numeric_date = (year * 372) + ((month - 1) * 31) + (day - 1) + hour / 24.0 + min / (24.0 * 60) + second / (24 * 60 * 60.0);
        if (isNaN(numeric_date) || (year === 1970)) {
          numeric_date = "xxx";
          has_unknowns = true;
        } else {
          if (numeric_date > max_numeric_date) max_numeric_date = numeric_date;
          if (numeric_date < min_numeric_date) min_numeric_date = numeric_date - 1;
        }
        $(this).attr('data-date-numeric', numeric_date);
        img = $(this).find('img');
        alt = img != null ? img.attr('alt') : void 0;
        if (alt) return img.attr('src', "/profile/" + (slugify(alt)));
      });
      if (has_unknowns) {
        max_numeric_date += 180;
        $(this).find(".timeline > ul > li[data-date-numeric='xxx']").attr('data-date-numeric', max_numeric_date);
      }
      $(this).find(".timeline > ul > li").tsort({
        attr: 'data-date-numeric',
        order: 'desc'
      });
      status_to_hebrew = function(status) {
        switch (status) {
          case "NEW":
            return "טרם התחיל";
          case "STUCK":
            return "תקוע";
          case "IN_PROGRESS":
            return "בתהליך";
          case "FIXED":
            return "יושם במלואו";
          case "WORKAROUND":
            return "יושם חלקית";
          case "IRRELEVANT":
            return "יישום ההמלצה כבר לא נדרש";
        }
      };
      is_good_status = function(status) {
        switch (status) {
          case "NEW":
            return false;
          case "STUCK":
            return false;
          case "IN_PROGRESS":
            return true;
          case "FIXED":
            return true;
          case "WORKAROUND":
            return false;
          case "IRRELEVANT":
            return true;
        }
      };
      gov_status = 'NEW';
      last_percent = 0.0;
      item_margins = 5;
      margins = 80;
      height = $(this).innerHeight() - margins;
      available_height = height;
      $(this).find(".timeline > ul > li .timeline-point").each(function() {
        return available_height = available_height - $(this).outerHeight() - item_margins;
      });
      top = 0;
      conflict = false;
      conflict_status = null;
      late = false;
      timeline_items = $(this).find(".timeline > ul > li");
      if ((timeline_items.length > 0) && $(timeline_items[0]).find('.timeline-point').hasClass('today')) {
        today_date = parseInt($(timeline_items[0]).attr('data-date-numeric'));
        last_update = parseInt($(this).find(".timeline > ul > li").attr('data-date-numeric'));
        if (today_date - last_update > 180) late = true;
      }
      NOT_SET = 1000;
      last_update_at = NOT_SET;
      today_at = NOT_SET;
      fixed_at = NOT_SET;
      for (i = _i = _ref = timeline_items.size() - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
        el = $(timeline_items[i]);
        point = el.find('.timeline-point:first');
        line = el.find('.timeline-line:first');
        status = (_ref2 = point.attr('data-status')) != null ? _ref2 : gov_status;
        if (point.hasClass('gov-update')) {
          conflict = false;
          gov_status = status != null ? status : gov_status;
          last_update_at = i;
        }
        if ((fixed_at === NOT_SET) && (gov_status === "FIXED" || gov_status === "IRRELEVANT")) {
          fixed_at = i;
        }
        its_today = false;
        if (point.hasClass("today")) {
          today_at = i;
          its_today = true;
        }
        if (point.hasClass('watch-update')) {
          if (is_good_status(gov_status) !== is_good_status(status)) {
            conflict = true;
            conflict_status = status;
          }
          if (is_good_status(status)) {
            point.addClass("watch-status-good");
          } else {
            point.addClass("watch-status-bad");
          }
          last_update_at = i;
        }
        if (today_at === NOT_SET || its_today) {
          point.find('.implementation-status').addClass("label-" + status);
          point.find('.implementation-status').html(status_to_hebrew(status));
          line.addClass("status-" + gov_status);
          if (conflict) point.addClass("conflict");
          if (point.hasClass('gov-update')) {
            point.addClass("gov-" + gov_status);
            if (is_good_status(gov_status)) {
              point.addClass("gov-status-good");
            } else {
              point.addClass("gov-status-bad");
            }
          }
        }
      }
      for (i = _j = _ref3 = timeline_items.size() - 1; _ref3 <= 0 ? _j <= 0 : _j >= 0; i = _ref3 <= 0 ? ++_j : --_j) {
        el = $(timeline_items[i]);
        line = el.find('.timeline-line:first');
        if ((fixed_at !== NOT_SET && i <= fixed_at) || i <= today_at) {
          line.addClass("future");
        } else {
          line.addClass("past");
          if (i <= last_update_at) line.addClass("unreported");
        }
      }
      $(this).find(".timeline > ul > li").each(function() {
        var date, item_height, percent, point_size;
        point = $(this).find('.timeline-point:first');
        line = $(this).find('.timeline-line:first');
        date = parseInt($(this).attr('data-date-numeric'));
        percent = (max_numeric_date - date) / (max_numeric_date - min_numeric_date);
        point_size = point.outerHeight() + item_margins;
        item_height = available_height * (percent - last_percent) + point_size;
        $(this).css('height', item_height);
        $(this).css('top', top);
        last_percent = percent;
        return top = top + item_height;
      });
      $(this).find(".timeline > ul > li:first > .timeline-line").remove();
      $(this).find(".timeline > ul > li:first").css('height', '3px');
      implementation_status = (_ref4 = $(this).find('.gov-update:last').attr('data-status')) != null ? _ref4 : "NEW";
      if (conflict) {
        $(this).find('.buxa-header').addClass('conflict');
      } else {
        $(this).find('.buxa-header').removeClass('conflict');
        if (is_good_status(implementation_status)) {
          $(this).find('.buxa-header').addClass('good');
        } else {
          $(this).find('.buxa-header').addClass('bad');
        }
      }
      $(this).attr('data-implementation-status', implementation_status);
      $(this).addClass("implementation-status-" + implementation_status);
      status_to_stamp_class = function(status) {
        switch (status) {
          case "NEW":
            return "notstarted";
          case "STUCK":
            return "stuck";
          case "IN_PROGRESS":
            return "inprogress";
          case "FIXED":
            return "done";
          case "WORKAROUND":
            return "workaround";
          case "IRRELEVANT":
            return "done";
        }
      };
      stamp_class = status_to_stamp_class(implementation_status);
      if (late) stamp_class = 'late';
      $(this).find('.buxa-header').before("<div class='stamp " + stamp_class + "'></div>");
      if (conflict) {
        stamp = status_to_hebrew(conflict_status);
        stamp_class = status_to_stamp_class(conflict_status);
        return $(this).find('.buxa-header').before("<div class='stamp conflicting " + stamp_class + "'></div>");
      }
    });
  };

  setup_summary = function() {
    var data, fixed, implemented, in_progress, irrelevant, news, stuck, total, workaround;
    total = $(".item.shown").size();
    stuck = $(".item.shown[data-implementation-status='STUCK']").size();
    news = $(".item.shown[data-implementation-status='NEW']").size();
    in_progress = $(".item.shown[data-implementation-status='IN_PROGRESS']").size();
    fixed = $(".item.shown[data-implementation-status='FIXED']").size();
    workaround = $(".item.shown[data-implementation-status='WORKAROUND']").size();
    irrelevant = $(".item.shown[data-implementation-status='IRRELEVANT']").size();
    data = {};
    if (total) data.total = total;
    stuck = news + workaround + stuck;
    if (stuck) data.stuck = stuck;
    implemented = fixed + irrelevant;
    if (implemented) data.implemented = implemented;
    if (in_progress) data.in_progress = in_progress;
    run_templates("summary", data, "#summary");
    $("#summary .total").click(function() {
      status_filter = null;
      do_search();
      return false;
    });
    $("#summary .stuck").click(function() {
      status_filter = ['STUCK', 'NEW', 'WORKAROUND'];
      do_search();
      return false;
    });
    $("#summary .implemented").click(function() {
      status_filter = ['FIXED', 'IRRELEVANT'];
      do_search();
      return false;
    });
    return $("#summary .in_progress").click(function() {
      status_filter = ['IN_PROGRESS'];
      do_search();
      return false;
    });
  };

  setup_subscriptions = function() {
    $("#subscribe").modal({
      'show': false
    });
    $(".watch").click(function() {
      var rel;
      rel = $(this).attr('rel');
      $("#subscribe_email").attr('data-slug', rel);
      $("#subscribe_form").attr('action', "/subscribe/" + rel);
      $("#subscribe").modal('show');
      return false;
    });
    $("#do_subscribe").click(function() {
      $("#subscribe_form").submit();
      return false;
    });
    return $("#subscribe_form").submit(function() {
      $.post($(this).attr('action'), {
        'email': $("#subscribe_email").val()
      }, function() {
        return $("#subscribe").modal('hide');
      });
      return false;
    });
  };

  setup_tags = function() {
    return $(".tags > ul > li, a[data-tag='true']").click(function() {
      search_term = $(this).text();
      show_watermark(false);
      $("#searchbox").val(search_term);
      $("#explanation").modal('hide');
      return update_history();
    });
  };

  process_data = function() {
    var book, explanation_needed, ___iced_passed_deferral, __iced_deferrals, __iced_k, _i, _len,
      _this = this;
    __iced_k = __iced_k_noop;
    ___iced_passed_deferral = iced.findDeferral(arguments);
    if (initialized) return;
    initialized = true;
    for (_i = 0, _len = all_books.length; _i < _len; _i++) {
      book = all_books[_i];
      $("#books").prepend("<li data-book='" + book + "' class='book'><a href='#'>" + book + "</a></li>");
    }
    run_templates("item", {
      items: loaded_data
    }, "#items");
    explanation_needed = true;
    if ((typeof localStorage !== "undefined" && localStorage !== null ? localStorage.explained : void 0) != null) {
      explanation_needed = false;
    }
    $("#explanation .close").click(function() {
      if (typeof localStorage !== "undefined" && localStorage !== null) {
        localStorage.explained = true;
      }
      $("#explanation").modal('hide');
      return false;
    });
    $("#show-explanation").click(function() {
      $("#explanation").modal('show');
      return false;
    });
    (function(__iced_k) {
      __iced_deferrals = new iced.Deferrals(__iced_k, {
        parent: ___iced_passed_deferral,
        filename: "gov-watch.iced",
        funcname: "process_data"
      });
      setTimeout((__iced_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return __iced_deferrals.ret = arguments[0];
          };
        })(),
        lineno: 536
      })), 50);
      __iced_deferrals._fulfill();
    })(function() {
      $.Isotope.prototype._positionAbs = function(x, y) {
        return {
          right: x,
          top: y
        };
      };
      $("#items").isotope({
        itemSelector: '.isotope-card',
        layoutMode: 'masonry',
        transformsEnabled: false,
        filter: ".shown",
        getSortData: {
          followers: function(e) {
            return -parseInt("0" + e.find('.watch').text());
          },
          original: function(e) {
            return "" + (e.attr('data-chapter')) + "/{e.attr('data-subchapter')}";
          },
          budget: function(e) {
            return -parseInt("0" + e.attr('cost'), 10);
          },
          comments: function(e) {
            var ret;
            ret = -parseInt("0" + e.find('.commentcount').text(), 10);
            return ret;
          }
        }
      });
      (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "gov-watch.iced",
          funcname: "process_data"
        });
        setTimeout((__iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              return __iced_deferrals.ret = arguments[0];
            };
          })(),
          lineno: 558
        })), 50);
        __iced_deferrals._fulfill();
      })(function() {
        setup_timeline();
        $(".item").css('visibility', 'inherit');
        setup_searchbox();
        setup_subscriptions();
        setup_tags();
        $("#books li.book a").click(function() {
          selected_book = $(this).html();
          return update_history();
        });
        $("#sort button").click(function() {
          var sort_measure;
          $("#sort button").removeClass('active');
          $(this).addClass('active');
          sort_measure = $(this).attr('value');
          $("#items").isotope('updateSortData', $(".isotope-card"));
          return $("#items").isotope({
            sortBy: sort_measure
          });
        });
        $("#explanation").modal({
          'show': explanation_needed
        });
        window.onhashchange = onhashchange;
        onhashchange();
        return load_fb_comment_count();
      });
    });
  };

  select_item = function(slug) {
    var item, url, x, _i, _len, _results;
    $('fb\\:comments').remove();
    $('fb\\:like').remove();
    if (slug) {
      $("#summary-header").css('visibility', 'hidden');
      $("#summary").html('');
      $("#sort button").addClass('disabled');
      _results = [];
      for (_i = 0, _len = loaded_data.length; _i < _len; _i++) {
        x = loaded_data[_i];
        if (x.slug === slug) {
          item = run_templates("single-item", x, "#single-item");
          set_title(x.base.book + ": " + x.base.subject);
          url = generate_url(slug);
          $("#single-item .fb").append("<fb:like href='" + url + "' send='true' width='590' show_faces='true' action='recommend' font='tahoma'></fb:like>");
          $("#single-item .fb").append("<fb:comments href='" + url + "' num_posts='2' width='590'></fb:comments>");
          if (window.FB) FB.XFBML.parse(item.get(0), function() {});
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    } else {
      $("#single-item").html('');
      $("#summary-header").css('visibility', 'inherit');
      return $("#sort button").removeClass('disabled');
    }
  };

  load_fb_comment_count = function() {
    $(".item").each(function() {
      var json, slug, ___iced_passed_deferral, __iced_deferrals, __iced_k,
        _this = this;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      slug = $(this).attr('rel');
      (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "gov-watch.iced"
        });
        $.get('https://api.facebook.com/method/fql.query', {
          query: "SELECT url,commentsbox_count FROM link_stat WHERE url='" + (generate_url(slug)) + "'",
          format: "json"
        }, (__iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              return json = arguments[0];
            };
          })(),
          lineno: 626
        })), "json");
        __iced_deferrals._fulfill();
      })(function() {
        return $(_this).find(".commentcount").html(json[0].commentsbox_count);
      });
    });
    return $("#items").isotope('updateSortData', $(".item"));
  };

  do_search = function() {
    var class_filter, found, re, rec, should_show, slug, st, tag, x, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
    re = RegExp(search_term, "ig");
    for (_i = 0, _len = loaded_data.length; _i < _len; _i++) {
      rec = loaded_data[_i];
      slug = rec.slug;
      rec = rec.base;
      should_show = search_term === "";
      if (search_term !== "") {
        _ref = [rec["recommendation"], rec["subject"], rec["result_metric"], rec["title"], rec["chapter"], rec["subchapter"], rec["responsible_authority"]["main"], rec["responsible_authority"]["secondary"]];
        for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
          x = _ref[_j];
          if (x) {
            found = x.indexOf(search_term) >= 0;
          } else {
            found = false;
          }
          should_show = should_show || found;
        }
        _ref2 = rec.tags;
        for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
          tag = _ref2[_k];
          if (tag === search_term) should_show = true;
        }
      }
      should_show = should_show && ((selected_book === "") || (rec.book === selected_book)) && (!selected_slug);
      $(".item[rel=" + slug + "]").toggleClass("shown", should_show);
    }
    setup_summary();
    if (status_filter) {
      class_filter = [
        (function() {
          var _l, _len4, _results;
          _results = [];
          for (_l = 0, _len4 = status_filter.length; _l < _len4; _l++) {
            st = status_filter[_l];
            _results.push(".shown.implementation-status-" + st);
          }
          return _results;
        })()
      ];
      class_filter = class_filter.join(",");
    } else {
      class_filter = ".shown";
    }
    class_filter = class_filter + ",.always-shown";
    $("#items").isotope({
      filter: class_filter
    });
    return $("#items").isotope("reLayout");
  };

  load_data = function() {
    return $.get("/api", data_callback, "json");
  };

  $(function() {
    var current_version, version, ___iced_passed_deferral, __iced_deferrals, __iced_k,
      _this = this;
    __iced_k = __iced_k_noop;
    ___iced_passed_deferral = iced.findDeferral(arguments);
    try {
      (function(__iced_k) {
        __iced_deferrals = new iced.Deferrals(__iced_k, {
          parent: ___iced_passed_deferral,
          filename: "gov-watch.iced"
        });
        $.get("/api/version", (__iced_deferrals.defer({
          assign_fn: (function() {
            return function() {
              return version = arguments[0];
            };
          })(),
          lineno: 685
        })), "json");
        __iced_deferrals._fulfill();
      })(function() {
        current_version = localStorage.version;
        localStorage.version = JSON.stringify(version);
        if (current_version && version !== JSON.parse(current_version)) {
          loaded_data = JSON.parse(localStorage.data);
          all_books = JSON.parse(localStorage.all_books);
          all_tags = JSON.parse(localStorage.all_tags);
          all_subjects = JSON.parse(localStorage.all_subjects);
          return process_data();
        } else {
          return load_data();
        }
      });
    } catch (error) {
      return load_data();
    }
  });

}).call(this);
