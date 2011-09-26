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
                val = if actual == fqn or actual == undefined then model else model[actual]
                if val instanceof ArrayProxy
                    list = []
                    for indx in [0..val.length-1]
                        list.push ( call( html, val, indx ) for call in createChildren )
                    makeTag( html, tag, actual, element, list, model )
                else
                    controls = (call( html, val ) for call in createChildren )
                    makeTag( html, tag, actual, element, controls, model )
        else
            ( html, model, idx ) ->
                actual = if id == "" then idx else id
                unless actual
                    makeTag( html, tag, actual, element, val, model )
                else
                    val = if actual == fqn or actual == undefined then model else model[actual]
                    x = 0
                    if val == undefined
                        if actual == "" or actual == undefined
                            makeTag( html, tag, "", element, model, model )
                        else
                            #html[tag]()
                            makeTag( html, tag, "", element, model, model )
                    else if val instanceof ArrayProxy
                        list =[]
                        for indx in [0..val.length-1]
                            list.push( makeTag( html, tag, indx, element, val[indx], model ) )
                        list
                    else
                        makeTag( html, tag, actual, element, val, model )

    makeTag = ( html, tag, id, template, val, model ) ->
        properties = {}
        content = template.textContent
        if id
            properties.id = id
            content = val
        if template.className
            properties.class = template.className
        if template.type
            properties.type = template.type
        if model[id]
            if model[id].onclick
                console.log "setting onlclick for element #{tag}"
                properties.onclick = model[id].onclick.toString()
            if model[id].onblur
                properties.onblur = model[id].onblur
            if model[id].text
                properties.value = model[id].text
                properties.textContent = model[id].text
                val = undefined
        html[tag]( properties, val or properties.textContent )


    @map = (model) ->
        fn = crawl this, namespace, @element, @map
        fn @html, model

    this