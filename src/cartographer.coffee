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
        console.log tag
        if element.children != undefined and element.children.length > 0
            createChildren = ( crawl( context, fqn, child ) for child in element.children )
            ( html, model, idx ) ->
                id = if id == "" or id == undefined then idx else id
                val = if id == fqn then model else model[id]
                if val instanceof ArrayProxy
                    index = 0
                    console.log tag + " - " + val.length
                    controls = ( ( call( html, val, index += 1) for call in createChildren ) for item in val )
                    html[tag]( { "id": id }, controls )
                else
                    controls = (call( html, val ) for call in createChildren )
                    html[tag]( { "id": id }, controls )
        else
            ( html, model, idx ) ->
                id = if id == "" or id == undefined then idx else id
                val = if id == fqn then model else model[id]
                x = 0
                if val instanceof ArrayProxy
                    html[tag]( { "id": x+=1}, item ) for item in val
                else
                    html[tag]( { "id": id }, val )

    @map = (model) ->
        fn = crawl this, namespace, @element, @map
        fn @html, model

    this