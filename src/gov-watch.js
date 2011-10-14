(function() {
  var data_callback, do_search, loaded_data;
  loaded_data = null;
  data_callback = function(data) {
    var html, template;
    loaded_data = data;
    template = $("script[name=item]").html();
    html = Mustache.to_html(template, {
      items: data
    });
    $("#items").html(html);
    return $("#searchbox").keyup(function() {
      return do_search();
    });
  };
  do_search = function() {
    var found_recm, found_subject, re, rec, recm, search_term, should_show, slug, subject, _i, _len;
    search_term = $("#searchbox").val();
    re = RegExp(search_term, "ig");
    for (_i = 0, _len = loaded_data.length; _i < _len; _i++) {
      rec = loaded_data[_i];
      slug = rec._srcslug;
      recm = rec.recommendation;
      subject = rec.subject;
      if (search_term === "") {
        found_recm = false;
        found_subject = false;
      } else {
        found_recm = recm.search(search_term) !== -1;
        found_subject = subject.search(search_term) !== -1;
      }
      should_show = found_recm || found_subject || (search_term === "");
      $(".item[rel=" + slug + "]").toggleClass("shown", should_show);
      if (found_recm) {
        recm = recm.replace(search_term, "<span class='highlight'>" + search_term + "</span>");
      }
      $(".item[rel=" + slug + "] .recommendation").html(recm);
      if (found_subject) {
        subject = subject.replace(search_term, "<span class='highlight'>" + search_term + "</span>");
      }
      $(".item[rel=" + slug + "] .subject").html(subject);
    }
    return window.setTimeout(function() {
      return $(".highlight").toggleClass('highlight-off', true);
    }, 10);
  };
  $(function() {
    return H.findRecords('data/gov/decisions/', data_callback);
  });
}).call(this);
