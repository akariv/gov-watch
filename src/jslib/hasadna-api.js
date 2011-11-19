var H = (function () { 
    var my = {}, 
    	APIServer = "http://api.yeda.us",
        useCacheNextRequest = true;

    // Low Level API

    function joinApiServerPath(b) {
    	var bb = b.charAt(0);
    	if ( bb != "/" ) {
    		return APIServer+"/"+b;
    	} else {
    		return APIServer+b;
    	}
    }
        
    function shouldCache(params) {
    	if ( !useCacheNextRequest ) {
    		params["hitcache"]=0;
    		useCacheNextRequest = true;
    	}
    }
        
    function DBServerGetJson(path,params,callback) {
    	shouldCache(params);
    	$.get(joinApiServerPath(path),
      		  params,
      		  function (data) {
      			 callback(data);
      		  },"jsonp");    	
    } 

    function DBServerGetHtml(path,params,elementId,callback) {
    	shouldCache(params);
    	$.get(joinApiServerPath(path),
    		  params,
			  function (data) {
				 $("#"+elementId).html(data);
				 if ( callback != undefined ) {
				 	callback($("#"+elementId));
    			 }
			  },"jsonp");
    }

    function DBServerPostJson(path,data,callback) {
        $.ajax( { url : joinApiServerPath(path)+"?o=json",
        		  data: data,
        	      contentType : "application/json",
        	      success: function (ret) {
      		         			if ( callback != undefined ) {
      		         				callback(ret);
      		         			}
          	    			}, 
          	      dataType: "json",
          	      processData: false,
          	      type: "POST" }
          	      );    	
    } 

    function DBServerDelete(path,callback) {
        $.ajax( { "url" : joinApiServerPath(path)+"?o=json",
        	      "type" : "DELETE", 
        		  "success": function (ret) {
      		         			if ( callback != undefined ) {
      		         				callback(ret);
      		         			}
          	    	  		 }
          	    } );    	
    } 

    my.dontCacheNext = function () {
    	useCacheNextRequest = false;
    }

    my.newRecord = function( path, data, callback ) {
        DBServerPostJson( path, JSON.stringify(data), callback );  
    }

    my.deleteRecord = function( path, callback ) {
        DBServerDelete( path, callback );  
    }

    my.getRecord = function(path,callback) {
    	var params = { "o"	   : "jsonp" };
    	DBServerGetJson(path,params,callback);
    }
    
    my.findRecords = function(path,callback,spec,fields,start,limit) {
    	var params = { "o"	   : "jsonp" };
    	if ( spec != undefined ) { params["query"] = JSON.stringify(spec); }
    	if ( fields != undefined ) { params["fields"] = fields; }
    	if ( start != undefined ) { params["start"] = start; }
    	if ( limit != undefined ) { params["limit"] = limit; }
    	DBServerGetJson(path,params,callback);
    }

    my.countRecordsTemplate = function(path,elementId,template,spec,fields,callback) {
    	var params = { "o"	   : "templatep:"+template,
    			       "count" : "1" };
    	if ( spec != undefined ) { params["query"] = JSON.stringify(spec); }
    	if ( fields != undefined ) { params["fields"] = fields; }
    	DBServerGetHtml(path,params,elementId,callback);
    }

    my.loadRecordTemplate = function(path,elementId,template,callback) {
    	var params = { "o"	   : "templatep:"+template };
    	DBServerGetHtml(path,params,elementId,callback);
    }

    my.loadRecordsTemplate = function(path,elementId,template,spec,fields,start,limit,callback) {
    	var params = { "o"	   : "templatep:"+template };
    	if ( spec != undefined ) { params["query"] = JSON.stringify(spec); }
    	if ( fields != undefined ) { params["fields"] = fields; }
    	if ( start != undefined ) { params["start"] = start; }
    	if ( limit != undefined ) { params["limit"] = limit; }
    	DBServerGetHtml(path,params,elementId,callback);
    }

    // Header
    my.loadLoginHeader = function(elementId) {
    	my.loadRecordTemplate("/data/",elementId,"login-header");
    }
    
    // Tagging
    my.loadTagsForRecord = function(path,elementId) {
    	var spec = { "reference" : path };
    	my.loadRecordsTemplate(
    			"/data/common/tags/",elementId,"snippet",
    			spec,null,null,null,
    			function (el) {
    				el.find("input[name=reference]").attr("value",path);
    				var select = el.find("select");
    				my.findRecords(
    						"/data/common/issues/",
    						function (data) {
    							for ( var i in data ) {
    								var tagname = data[i];
    								select.append("<option value='"+tagname._src+"'>"+tagname.name+"</option>");
    							}
    				});
    				el.find("form").submit( function() {
    					var selected_item = el.find("select option:selected").val();
//    					var slug = path+"/"+selected_item;
//    					slug = slug.replace(/\//g,"__");
    					my.newRecord("/data/common/tags/",//+slug,
    								{ "reference" : path,
    						          "tag" : { "_ref" : selected_item } },
    						        function() {
    						        	my.dontCacheNext();
    						        	my.loadTagsForRecord(path,elementId); 
    						        } );
    					return false;
    				} );
    				el.find(".H-tag").click( function () {
    					var src = $(this).attr("rel");
    					my.deleteRecord( src, function() {
    						my.dontCacheNext();
    						my.loadTagsForRecord(path,elementId); 
    					} );
    				} );
    			}
    	);
    }
    	
    // Starring
    my.loadStarsForRecord = function(path,elementId) {
    	var spec = { "reference" : path };
		my.countRecordsTemplate(
    			"/data/common/stars/",elementId, "count",
    			spec,null,
    			function (el) {
    				var slug = path+"/"+H_login_data.key;
    				slug = slug.replace(/\//g,"__");

    				el.find(".H-stars-votes").attr("id",slug); //TODO
    				my.loadRecordTemplate(
    						"/data/common/stars/"+slug,
    						slug,
    						"vote",
    						function () {
    							el.find(".H-stars-vote.H-stars-not-starred").click( function () {
			    					my.newRecord("/data/common/stars/"+slug,
	    	    								{ "reference" : path },
	    	    						        function() {
	    	    									my.dontCacheNext();
	    	    						        	my.loadStarsForRecord(path,elementId); 
	    	    						        } );    								
    							} );
    							el.find(".H-stars-vote.H-stars-starred").click( function () {
			    					my.deleteRecord("/data/common/stars/"+slug,
			    									function() {
			    										my.dontCacheNext();
			    										my.loadStarsForRecord(path,elementId); 
	    	    						        	} );    								
    							} );
    						}
    				);
    			}
    	);
    }
    
    return my; 
}());
