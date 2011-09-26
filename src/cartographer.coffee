Cartographer = (target, namespace) ->
    @element = $(target)[0]
    @map = ->
    @html = DOMBuilder.dom

    createFqn = ( namespace, id ) ->
        if id == undefined or id == ""
            result = namespace
        else if namespace == undefined or namespace == ""
            result = id
        else
            result = "#{namespace}.#{id}"
        result

    @fqn = createFqn namespace, @element["id"]

    crawl = ( root, context, namespace, element ) ->
        id = element["id"]
        fqn = createFqn namespace, id
        tag = element.tagName.toUpperCase()
        context = context or root

        if element.children != undefined and element.children.length > 0
            createChildren = ( crawl( root, context, fqn, child ) for child in element.children )

            ( html, model, idx ) ->
                actualId = if id == "" then idx else id
                val = if actualId == fqn or actualId == undefined then model else model[actualId]
                if val instanceof ArrayProxy
                    list = []
                    for indx in [0..val.length-1]
                        list.push ( call( html, val, indx ) for call in createChildren )
                    makeTag( html, tag, actualId, element, list, root, model )
                else
                    controls = (call( html, val ) for call in createChildren )
                    makeTag( html, tag, actualId, element, controls, root, model )
        else
            ( html, model, idx ) ->
                actualId = if id == "" then idx else id
                
                val = if actualId == fqn then model else model[actualId]
                if val instanceof ArrayProxy
                    list =[]
                    for indx in [0..val.length-1]
                        list.push( makeTag( html, tag, indx, element, val[indx], root, model ) )
                    list
                else
                    makeTag( html, tag, actualId, element, val, root, model )

    makeTag = ( html, tag, id, template, val, root, model ) ->
        properties = {}
        content = if val then val else template.textContent

        if id
            properties.id = id

        if template.className
            properties.class = template.className

        if template.type
            properties.type = template.type

        element = html[tag]( properties, content )

        if model[id]
            if model[id].onclick
                element.onclick = model[id].onclick.bind(root)
            if model[id].onblur
                element.onblur = model[id].onblur.bind(root)
            if model[id].text
                element.value = model[id].text
                element.textContent = model[id].text
        element


    @map = (model) ->
        fn = crawl model, this, namespace, @element, @map
        fn @html, model

    this