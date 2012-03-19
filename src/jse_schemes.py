##### encoding: utf8 #####
import json

issue_scheme = {
    "type"     : "obj",
    "children" : [ { "name" : "slug",
                     "props": { "title" : u"מזהה",
                                "type"  : "str" },
                     },
                   { "name" : "book",
                     "props": { "title"  : u'דו"ח',
                                "type"   : "str" },
                     },
                   { "name" : "chapter",
                     "props": { "title"  : u'פרק',
                                "type"   : "str" },
                     },
                   { "name" : "subchapter",
                     "props": { "title"  : u'סעיף',
                                "type"   : "str",
                                "optional" : True },
                     },
                   { "name" : "subject",
                     "props": { "title"  : u'כותרת',
                                "type"   : "str" },
                     },
                   { "name" : "recommendation",
                     "props": { "title"  : u'פירוט',
                                "type"   : "text" },
                     },
                   { "name" : "result_metric",
                     "props": { "title"  : u'מטרה',
                                "type"   : "text" },
                     },
                   { "name" : "budget",
                     "props": { "title"  : u'עלות כספית',
                                "type"   : "obj",
                                "children" : [ { "name" : "description",
                                                 "props": { "title"  : u'תיאור',
                                                            "type"   : "text",
                                                            "optional" : True},
                                                 },
                                               { "name" : "millions",
                                                 "props": { "title"  : u'סכום במיליונים',
                                                            "type"   : "num" },
                                                 },
                                               { "name" : "year_span",
                                                 "props": { "title"  : u'על פני כמה שנים',
                                                            "type"   : "num" },
                                                 },
                                               ] 
                                },
                     },
                   { "name" : "responsible_authority",
                     "props": { "title"  : u'גורם אחראי',
                                "type"   : "str" },
                     },
                   { "name" : "tags",
                     "props": { "title"  : u'תגיות',
                                "type"   : "arr",
                                "eltype" : { "type" : "str" } 
                                }
                     },
                   { "name" : "description",
                     "props": { "title"  : u'דברי הסבר',
                                "optional" : True,
                                "type"   : "text" }
                     },
                   { "name" : "implementation_status",
                     "props": { "title"  : u'סטטוס יישום',
                                "type"   : "select",
                                "options": [ [ "NEW"         , u'טרם התחיל' ],
                                             [ "STUCK"       , u'תקוע' ],
                                             [ "IN_PROGRESS" , u'בתהליך' ],
                                             [ "FIXED"       , u'יושם במלואו' ],
                                             [ "WORKAROUND"  , u'יושם חלקית' ],
                                             [ "IRRELEVANT"  , u'כבר לא רלוונטי' ]
                                             ]
                                }
                     },
                   { "name" : "implementation_status_text",
                     "props": { "title"  : u'הסבר לסטטוס היישום',
                                "optional" : True,
                                "type"   : "text" }
                     },
                   { "name" : "timeline",
                     "props": { "title"  : u'לוח זמנים',
                                "type"   : "arr",
                                "eltype" : { "type" : "obj",
                                             "title": u'אבן דרך',
                                             "children" : [ { "name" : "milestone_name",
                                                              "props": { "type" : "str",
                                                                         "title" : u'שם אבן הדרך' }
                                                              },
                                                            { "name" : "description",
                                                              "props": { "type" : "text",
                                                                         "optional" : True,
                                                                         "title" : u'תיאור מפורט' }
                                                              },
                                                            { "name" : "due_date",
                                                              "props": { "type" : "date",
                                                                         "optional" : True,
                                                                         "title": u'תאריך יעד מתוכנן' }
                                                              },
                                                            { "name" : "action_date",
                                                              "props": { "type" : "date",
                                                                         "title": u'תאריך ביצוע בפועל',
                                                                         "optional" : True }
                                                              },
                                                            { "name" : "links",
                                                              "props": { "type" : "arr",
                                                                         "title": u'קישורים',
                                                                         "eltype": { "type" : "obj",
                                                                                     "children" : [ { "name" : "url",
                                                                                                      "props" : { "type" : "str",
                                                                                                                  "title": "URL" }
                                                                                                      },
                                                                                                    { "name" : "description",
                                                                                                      "props" : { "type" : "str",
                                                                                                                  "title": u'תיאור' }
                                                                                                      },
                                                                                                    ]
                                                                                     }
                                                                         }
                                                              },
                                                            ]
                                             }
                                }             
                     },
      ]
}

print "issue_scheme = %s" % json.dumps(issue_scheme,indent=0)    
