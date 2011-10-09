(function() {
  var data_callback;
  data_callback = function(data) {
    var html, template;
    template = $("script[name=item-template]").html();
    html = Mustache.to_html(template, data);
    return $("#container").html(html);
  };
  $(function() {
    return bla;
  });
}).call(this);
