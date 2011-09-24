Cartographer = (target, namespace) ->
    @element = $(target)[0]
    @map = ->
    @fqn = if namespace == "" or namespace == undefined
            @element["id"]
          else
            buildFqn namespace, @element["id"]
    @html = DOMBuilder.html

    createFqn = ( namespace, id ) ->
        if id == undefined or id == ""
            result = namespace
        else if namespace == undefined or namespace == ""
            result = id
        else
            result = "#{namespace}.#{id}"
        result

    crawl = ( context, namespace, element ) ->
        id = element["id"]
        fqn = createFqn namespace, id
        tag = element.tagName.toUpperCase()
        if element.children != undefined and element.children.length > 0
            createChildren = ( crawl( context, fqn, child ) for child in element.children )
            ( html, model, idx ) ->
                actual = if id == "" then idx else id
                val = if actual == fqn then model else model[actual]
                if val instanceof ArrayProxy
                    list = []
                    for indx in [0..val.length-1]
                        list.push ( call( html, val, indx ) for call in createChildren )
                    makeTag( html, tag, actual, element, list )
                else
                    controls = (call( html, val ) for call in createChildren )
                    makeTag( html, tag, actual, element, controls )
        else
            ( html, model, idx ) ->
                actual = if id == "" then idx else id
                val = if actual == fqn then model else model[actual]
                x = 0
                if val == undefined
                    if actual == "" or actual == undefined
                        makeTag( html, tag, "", element, element.textContent )
                    else
                        html[tag]()
                else if val instanceof ArrayProxy
                    list =[]
                    for indx in [0..val.length-1]
                        list.push( makeTag( html, tag, indx, element, val[indx] ) )
                    list
                else
                    makeTag( html, tag, actual, element, val )

    makeTag = ( html, tag, id, template, val ) ->
        properties =
            id: id
        if template.className
            properties.class = template.className
        if val.onclick
            properties.onclick = val.onclick
        if val.onblur
            properties.onblur = val.onblur
        html[tag]( properties, val )


    @map = (model) ->
        fn = crawl this, namespace, @element, @map
        fn @html, model

    this