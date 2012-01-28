(function() {
  var HASH_SEP, all_books, all_chapters, data_callback, do_search, generate_hash, generate_url, gs_data_callback, initialized, load_from_gdocs, loaded_data, onhashchange, process_data, search_term, select_item, selected_book, selected_chapter, selected_slug, show_watermark, skip_overview, start_handlers, update_history, wm_shown;
  loaded_data = null;
  all_books = [];
  all_chapters = {};
  selected_book = "";
  selected_chapter = "";
  search_term = "";
  selected_slug = "";
  skip_overview = false;
  HASH_SEP = '&';
  generate_hash = function(selected_book, selected_chapter, search_term, slug) {
    if (slug) {
      return "" + selected_book + HASH_SEP + selected_chapter + HASH_SEP + search_term + HASH_SEP + slug;
    } else {
      return "" + selected_book + HASH_SEP + selected_chapter + HASH_SEP + search_term + HASH_SEP;
    }
  };
  generate_url = function(slug) {
    return "http://" + window.location.host + "/#" + (generate_hash("", "", "", slug));
  };
  update_history = function() {
    return setTimeout(function() {
      return window.location.hash = generate_hash(selected_book, selected_chapter, search_term);
    }, 0);
  };
  onhashchange = function() {
    var chapter, hash, slug, splits, _i, _len, _ref;
    hash = window.location.hash;
    hash = hash.slice(1, hash.length);
    splits = hash.split(HASH_SEP);
    if (splits.length > 4 || splits.length < 3) {
      selected_book = all_books[0];
      selected_chapter = "";
      update_history();
      return;
    }
    slug = null;
    if (splits.length === 3) {
      selected_book = splits[0], selected_chapter = splits[1], search_term = splits[2];
    }
    if (splits.length === 4) {
      selected_book = splits[0], selected_chapter = splits[1], search_term = splits[2], slug = splits[3];
    }
    $("#books option[value='" + selected_book + "']").attr('selected', 'selected');
    if (all_chapters[selected_book]) {
      $("#chapters").html("<option value=''>כל הפרקים</option>");
      _ref = all_chapters[selected_book];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chapter = _ref[_i];
        $("#chapters").append("<option value='" + chapter + "'>" + chapter + "</option>");
      }
    } else {
      $("#chapters").html("<option value=''>-</option>");
    }
    $("#chapters option[value='" + selected_chapter + "']").attr('selected', 'selected');
    if (search_term !== "") {
      show_watermark(false);
      $("#searchbox").val(search_term);
    }
    do_search();
    if (slug) {
      selected_slug = slug;
      return skip_overview = true;
    }
  };
  wm_shown = false;
  show_watermark = function(show) {
    if (show) {
      $("#searchbox").val("חיפוש חופשי בתוך ההמלצות");
    } else {
      if (wm_shown) {
        $("#searchbox").val("");
      }
    }
    wm_shown = show;
    return $("#searchbox").toggleClass('watermark', show);
  };
  gs_data_callback = function(data) {
    var cell, col, contents, entries, entry, field, field_titles, idx, row, _i, _len;
    entries = data.feed.entry;
    field_titles = {};
    loaded_data = [];
    for (_i = 0, _len = entries.length; _i < _len; _i++) {
      entry = entries[_i];
      cell = entry.gs$cell;
      row = parseInt(cell.row);
      col = parseInt(cell.col);
      contents = cell.$t;
      if (!contents) {
        contents = "";
      }
      if (row === 1) {
        field_titles[col] = contents;
      } else {
        idx = row - 2;
        field = field_titles[col];
        if (col === 1) {
          loaded_data[idx] = {
            '_srcslug': "" + row
          };
        }
        loaded_data[idx][field] = contents;
      }
    }
    return data_callback(loaded_data);
  };
  window.gs_data_callback = gs_data_callback;
  data_callback = function(data) {
    var book, chapters, rec, _i, _len;
    all_books = {};
    for (_i = 0, _len = data.length; _i < _len; _i++) {
      rec = data[_i];
      if (!all_books[rec.book]) {
        all_books[rec.book] = {};
      }
      all_books[rec.book][rec.chapter] = true;
    }
    all_chapters = {};
    for (book in all_books) {
      chapters = all_books[book];
      all_chapters[book] = Object.keys(chapters);
    }
    all_books = Object.keys(all_books);
    if (localStorage) {
      localStorage.data = JSON.stringify(data);
      localStorage.all_books = JSON.stringify(all_books);
      localStorage.all_chapters = JSON.stringify(all_chapters);
    }
    return process_data();
  };
  initialized = false;
  process_data = function() {
    var book, do_list, html, list_template, template, _i, _len;
    if (initialized) {
      return;
    }
    initialized = true;
    $("#books").html("<option value=''>\u05d4\u05db\u05dc</option>");
    for (_i = 0, _len = all_books.length; _i < _len; _i++) {
      book = all_books[_i];
      $("#books").append("<option value='" + book + "'>" + book + "</option>");
    }
    template = $("script[name=item]").html();
    list_template = $("script[name=list]").html();
    do_list = function(text) {
      return Mustache.to_html(list_template, {
        items: text,
        linkify: function() {
          return function(text, render) {
            text = render(text);
            return text = text.replace(/\[(.+)\]/, "<a href='$1'>\u05e7\u05d9\u05e9\u05d5\u05e8</a>");
          };
        }
      });
    };
    html = Mustache.to_html(template, {
      items: loaded_data,
      none_val: function() {
        return function(text, render) {
          text = render(text);
          if (text === "") {
            return "\u05d0\u05d9\u05df";
          } else {
            return text;
          }
        };
      },
      semicolon_list: function() {
        return function(text, render) {
          text = render(text);
          text = text.split(';');
          return text = do_list(text);
        };
      }
    });
    $("#items").html(html);
    return setTimeout(start_handlers, 0);
  };
  start_handlers = function() {
    var modal_options;
    $.Isotope.prototype._positionAbs = function(x, y) {
      return {
        right: x,
        top: y
      };
    };
    $("#items").isotope({
      itemSelector: '.item',
      layoutMode: 'masonry',
      transformsEnabled: false,
      getSortData: {
        chapter: function(e) {
          return e.find('.chapter-text').text();
        },
        recommendation: function(e) {
          return e.find('.recommendation-text').text();
        },
        budget: function(e) {
          return -parseInt("0" + e.attr('cost'), 10);
        },
        oneitem: function(e) {
          if (e.attr("rel") === selected_slug) {
            return 0;
          } else {
            return 1;
          }
        }
      }
    });
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
      if ($(this).val() === "") {
        return show_watermark(true);
      }
    });
    $("#searchbar").submit(function() {
      return false;
    });
    $("#books").change(function() {
      selected_book = $("#books").val();
      selected_chapter = "";
      return update_history();
    });
    $("#chapters").change(function() {
      selected_chapter = $("#chapters").val();
      return update_history();
    });
    $("#sort").change(function() {
      var sort_measure;
      sort_measure = $("#sort").val();
      return $("#items").isotope({
        sortBy: sort_measure
      });
    });
    $(".item").click(function() {
      return select_item($(this));
    });
    window.onhashchange = onhashchange;
    onhashchange();
    modal_options = {
      backdrop: true,
      keyboard: true,
      show: false
    };
    $("#overview").modal(modal_options);
    $("#overview-close").click(function() {
      return $("#overview").modal('hide');
    });
    if (skip_overview) {
      return select_item($(".item[rel=" + selected_slug + "]"));
    } else {
      return $("#overview").modal('show');
    }
  };
  select_item = function(item) {
    var url;
    $('fb\\:comments').remove();
    if (item.hasClass("bigger")) {
      item.removeClass("bigger");
      return $("#items").isotope('reLayout', function() {});
    } else {
      $(".item").removeClass("bigger");
      item.addClass("bigger");
      selected_slug = item.attr("rel");
      url = generate_url(selected_slug);
      item.append("<fb:comments href='" + url + "' num_posts='2' width='590'></fb:comments>");
      return FB.XFBML.parse(item.get(0), function() {
        return setTimeout(function() {
          $("#items").isotope('reLayout');
          return setTimeout(function() {
            return $(".item[rel=" + selected_slug + "]").scrollintoview();
          }, 1000);
        }, 1000);
      });
    }
  };
  $("#items").isotope('reLayout');
  do_search = function() {
    var field, found, new_fields, re, rec, should_show, slug, _i, _j, _len, _len2, _ref;
    re = RegExp(search_term, "ig");
    for (_i = 0, _len = loaded_data.length; _i < _len; _i++) {
      rec = loaded_data[_i];
      slug = rec._srcslug;
      should_show = search_term === "";
      new_fields = {};
      _ref = ["recommendation", "subject", "result_metric", "title", "execution_metric", "chapter", "responsible_authority"];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        field = _ref[_j];
        if (search_term === "") {
          found = false;
        } else {
          if (rec[field]) {
            found = rec[field].search(search_term) !== -1;
            new_fields[field] = rec[field].replace(search_term, "<span class='highlight'>" + search_term + "</span>");
          } else {
            found = false;
            new_fields[field] = null;
          }
        }
        should_show = should_show || found;
      }
      should_show = should_show && ((selected_book === "") || (rec.book === selected_book)) && ((selected_chapter === "") || (rec.chapter === selected_chapter));
      $(".item[rel=" + slug + "]").toggleClass("shown", should_show);
      $(".item[rel=" + slug + "] .chapter-text").html(new_fields["chapter"]);
      $(".item[rel=" + slug + "] .recommendation-text").html(new_fields["recommendation"]);
      $(".item[rel=" + slug + "] .execution_metric-text").html(new_fields["execution_metric"]);
      $(".item[rel=" + slug + "] .responsible_authority-text").html(new_fields["responsible_authority"]);
      $(".item[rel=" + slug + "] .subject-text").html(new_fields["subject"]);
      $(".item[rel=" + slug + "] .result_metric-text").html(new_fields["result_metric"]);
      $(".item[rel=" + slug + "] .title-text").html(new_fields["title"]);
    }
    $("#items").isotope({
      filter: ".shown"
    });
    return window.setTimeout(function() {
      return $(".highlight").toggleClass('highlight-off', true);
    }, 10);
  };
  load_from_gdocs = function() {
    return $.get("https://spreadsheets.google.com/feeds/cells/0AurnydTPSIgUdE5DN2J5Y1c0UGZYbnZzT2dKOFgzV0E/od6/public/values?alt=json-in-script", gs_data_callback, "jsonp");
  };
  $(function() {
    try {
      loaded_data = JSON.parse(localStorage.data);
      all_books = JSON.parse(localStorage.all_books);
      all_chapters = JSON.parse(localStorage.all_chapters);
      process_data();
      return setTimeout(load_from_gdocs, 10000);
    } catch (error) {
      return load_from_gdocs();
    }
  });
}).call(this);
