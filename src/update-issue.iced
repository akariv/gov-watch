update_scheme = {"type": "obj", "children": [{"name": "description", "props": {"type": "text", "optional": true, "title": "\u05d3\u05d1\u05e8\u05d9 \u05d4\u05e1\u05d1\u05e8"}}, {"name": "implementation_status", "props": {"type": "select", "options": [["NEW", "\u05d8\u05e8\u05dd \u05d4\u05ea\u05d7\u05d9\u05dc"], ["STUCK", "\u05ea\u05e7\u05d5\u05e2"], ["IN_PROGRESS", "\u05d1\u05ea\u05d4\u05dc\u05d9\u05da"], ["FIXED", "\u05d9\u05d5\u05e9\u05dd \u05d1\u05de\u05dc\u05d5\u05d0\u05d5"], ["WORKAROUND", "\u05d9\u05d5\u05e9\u05dd \u05d7\u05dc\u05e7\u05d9\u05ea"], ["IRRELEVANT", "\u05d9\u05d9\u05e9\u05d5\u05dd \u05d4\u05d4\u05de\u05dc\u05e6\u05d4 \u05db\u05d1\u05e8 \u05dc\u05d0 \u05e0\u05d3\u05e8\u05e9"]], "title": "\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "implementation_status_text", "props": {"type": "text", "optional": true, "title": "\u05d4\u05e1\u05d1\u05e8 \u05dc\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d4\u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "links", "props": {"type": "arr", "eltype": {"type": "obj", "children": [{"name": "url", "props": {"type": "str", "title": "URL"}}, {"name": "description", "props": {"type": "str", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8"}}]}, "title": "\u05e7\u05d9\u05e9\u05d5\u05e8\u05d9\u05dd"}}]}

$( () ->
        $('#savedialog').modal()
        $('#savedialog').modal('hide')
        $('#updaters').modal()
        $('#updaters').modal('hide')
        J = new JSE($("#body"), update_scheme)
        $("#submit").click () ->
                newval = J.getvalue()
                try
                        J.setvalue(newval)
                        $("#errors").html("&nbsp;")
                        $("#saver input[name='data']").val(JSON.stringify(newval))
                        $("#saver").submit()
                catch e
                        $("#errors").html(e)
                $("#body").html("")
                J.render()
                $('#savedialog').modal('hide')

        window.onhashchange = (e) ->
                hash = window.location.hash
                hash = hash[1..hash.length]
                $("#saver").attr("action","/update/#{hash}")
                await $.getJSON("/api/#{hash}",(defer data))
                updaters = data['updates']
                updaters = Object.keys(updaters)
                $("#updaters ul").html('<li>ארגון חדש</li>')
                for updater in updaters
                        $("#updaters ul").append("<li>#{updater}</li>")
                $('#updaters li').click(  ->
                        $("#updaters").modal('hide')
                        username = $(this).html()
                        J.setvalue(data['updates'][username][0])
                        $("#body").html("")
                        J.render()
                        )
                $("#updaters").modal('show')

        window.onhashchange()
)
