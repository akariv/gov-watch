(function() {
  var data_callback;
  data_callback = function(data) {
    var html, template;
    template = $("script[name=item]").html();
    html = Mustache.to_html(template, {
      items: data
    });
    return $("#container").html(html);
  };
  $(function() {
    return H.findRecords('data/gov/decisions/', data_callback);
  });
}).call(this);
