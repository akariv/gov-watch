issue_scheme = {"type": "obj", "children": [{"name": "book", "props": {"type": "str", "title": "\u05d3\u05d5\"\u05d7"}}, {"name": "chapter", "props": {"type": "str", "title": "\u05e4\u05e8\u05e7"}}, {"name": "subchapter", "props": {"optional": true, "type": "str", "title": "\u05e1\u05e2\u05d9\u05e3"}}, {"name": "subject", "props": {"type": "str", "title": "\u05db\u05d5\u05ea\u05e8\u05ea"}}, {"name": "recommendation", "props": {"type": "text", "title": "\u05e4\u05d9\u05e8\u05d5\u05d8"}}, {"name": "result_metric", "props": {"type": "text", "title": "\u05de\u05d3\u05d3 \u05d4\u05ea\u05d5\u05e6\u05d0\u05d4"}}, {"name": "budget", "props": {"type": "obj", "children": [{"name": "description", "props": {"optional": true, "type": "text", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8"}}, {"name": "millions", "props": {"type": "num", "title": "\u05e1\u05db\u05d5\u05dd \u05d1\u05de\u05d9\u05dc\u05d9\u05d5\u05e0\u05d9\u05dd"}}, {"name": "year_span", "props": {"type": "num", "title": "\u05e2\u05dc \u05e4\u05e0\u05d9 \u05db\u05de\u05d4 \u05e9\u05e0\u05d9\u05dd"}}], "title": "\u05e2\u05dc\u05d5\u05ea \u05db\u05e1\u05e4\u05d9\u05ea"}}, {"name": "responsible_authority", "props": {"type": "obj", "children": [{"name": "main", "props": {"type": "str", "title": "\u05d2\u05d5\u05e8\u05dd \u05e8\u05d0\u05e9\u05d9"}}, {"name": "secondary", "props": {"optional": true, "type": "str", "title": "\u05d2\u05d5\u05e8\u05de\u05d9\u05dd \u05de\u05e9\u05e0\u05d9\u05d9\u05dd"}}], "title": "\u05d2\u05d5\u05e8\u05dd \u05d0\u05d7\u05e8\u05d0\u05d9"}}, {"name": "tags", "props": {"optional": true, "type": "arr", "eltype": {"type": "str", "title": "tag"}, "title": "\u05ea\u05d2\u05d9\u05d5\u05ea"}}, {"name": "timeline", "props": {"type": "arr", "eltype": {"type": "obj", "children": [{"name": "milestone_name", "props": {"type": "str", "title": "\u05e9\u05dd \u05d0\u05d1\u05df \u05d4\u05d3\u05e8\u05da"}}, {"name": "description", "props": {"optional": true, "type": "text", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8 \u05de\u05e4\u05d5\u05e8\u05d8"}}, {"name": "due_date", "props": {"optional": true, "type": "date", "title": "\u05ea\u05d0\u05e8\u05d9\u05da \u05d9\u05e2\u05d3 \u05de\u05ea\u05d5\u05db\u05e0\u05df"}}, {"name": "start", "props": {"optional": true, "type": "bool", "title": "\u05d4\u05d0\u05dd \u05d6\u05d5\u05d4\u05d9 \u05e0\u05e7\u05d5\u05d3\u05ea \u05d4\u05d4\u05ea\u05d7\u05dc\u05d4 \u05e9\u05dc \u05d4\u05d4\u05de\u05dc\u05e6\u05d4?"}}, {"name": "completion", "props": {"optional": true, "type": "bool", "title": "\u05d4\u05d0\u05dd \u05d6\u05d5\u05d4\u05d9 \u05e0\u05e7\u05d5\u05d3\u05ea \u05d4\u05e1\u05d9\u05d5\u05dd \u05e9\u05dc \u05d4\u05d4\u05de\u05dc\u05e6\u05d4?"}}], "title": "\u05d0\u05d1\u05df \u05d3\u05e8\u05da"}, "title": "\u05dc\u05d5\u05d7 \u05d6\u05de\u05e0\u05d9\u05dd"}}]}
update_scheme = {"type": "obj", "children": [{"name": "description", "props": {"type": "text", "optional": true, "title": "\u05d3\u05d1\u05e8\u05d9 \u05d4\u05e1\u05d1\u05e8"}}, {"name": "implementation_status", "props": {"type": "select", "options": [["NEW", "\u05d8\u05e8\u05dd \u05d4\u05ea\u05d7\u05d9\u05dc"], ["STUCK", "\u05ea\u05e7\u05d5\u05e2"], ["IN_PROGRESS", "\u05d1\u05ea\u05d4\u05dc\u05d9\u05da"], ["FIXED", "\u05d9\u05d5\u05e9\u05dd \u05d1\u05de\u05dc\u05d5\u05d0\u05d5"], ["WORKAROUND", "\u05d9\u05d5\u05e9\u05dd \u05d7\u05dc\u05e7\u05d9\u05ea"], ["IRRELEVANT", "\u05d9\u05d9\u05e9\u05d5\u05dd \u05d4\u05d4\u05de\u05dc\u05e6\u05d4 \u05db\u05d1\u05e8 \u05dc\u05d0 \u05e0\u05d3\u05e8\u05e9"]], "title": "\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "implementation_status_text", "props": {"type": "text", "optional": true, "title": "\u05d4\u05e1\u05d1\u05e8 \u05dc\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d4\u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "links", "props": {"type": "arr", "eltype": {"type": "obj", "children": [{"name": "url", "props": {"type": "str", "title": "URL"}}, {"name": "description", "props": {"type": "str", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8"}}]}, "title": "\u05e7\u05d9\u05e9\u05d5\u05e8\u05d9\u05dd"}}]}
$( () ->
        $('#savedialog').modal()
        $('#savedialog').modal('hide')
        J = new JSE($("#body"), issue_scheme)
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
                $("#saver").attr("action","/base/#{hash}")
                await $.getJSON("/api/#{hash}",(defer data))
                J.setvalue(data['base'])
                $("#body").html("")
                J.render()

        window.onhashchange()
)
