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

    @eventChannel = postal.channel(@fqn + "_events")
    
    channel = @eventChannel

    eventHandlers =
      click: "onclick"
      dblclick: "ondblclick"
      mousedown: "onmousedown"
      mouseup: "onmouseup"
      mouseove: "onmouseover"
      mousemove: "onmousemove"
      mouseout: "onmouseout"
      keydown: "onkeydown"
      keypress: "onkeypress"
      keyup: "onkeyup"
      select: "onselect"
      change: "onchange"
      focus: "onfocus"
      blur: "onblur"
      scroll: "onscroll"
      resize: "onresize"
      submit: "onsubmit"

    modelTargets =
      hide: "hidden"
      value: ["value", "textContent"]

    templateProperties =
      id: "id"
      name: "name"
      class: "className"
      type: "type"

    crawl = ( context, root, namespace, element ) ->
        id = element["id"]
        fqn = createFqn namespace, id
        tag = element.tagName.toUpperCase()
        context = context or root

        if element.children != undefined and element.children.length > 0
            createChildren = ( crawl( context, root, fqn, child ) for child in element.children )

            ( html, model, parentFqn, idx ) ->
                actualId = if id == "" then idx else id
                myFqn = createFqn parentFqn, actualId
                val = if actualId == fqn or actualId == undefined then model else model[actualId]
                if val instanceof ArrayProxy
                    list = []
                    for indx in [0..val.length-1]
                        list.push ( call( html, val, myFqn, indx ) for call in createChildren )
                    makeTag( html, tag, element, actualId, list, root, model )
                else
                    controls = ( call( html, val, myFqn ) for call in createChildren )
                    makeTag( html, tag, element, actualId, controls, root, model )
        else
            ( html, model, parentFqn, idx ) ->
                actualId = if id == "" then idx else id
                myFqn = createFqn parentFqn, actualId
                val = if actualId == fqn then model else model[actualId]
                element = makeTag( html, tag, element, actualId, val, root, model )
                setupEvents( model[actualId], root, myFqn, element, context )
                context[myFqn] = element
                element

    makeTag = ( html, tag, template, id, val, root, model ) ->
        properties = {}
        content = if val then val else template.textContent
        if id
            properties.id = id
        if template
          copyProperties template, properties, templateProperties
        element = html[tag]( properties, content )
        if model[id]
          copyProperties model[id], element, modelTargets
        element

    setupEvents = ( model, root, fqn, element, context ) ->
      if model
        (wireup x, eventHandlers[x], model, root, fqn, element, context ) for x in _.keys(eventHandlers)

    wireup = ( alias, event, model, root, fqn, element, context ) ->
      handler = model[alias]
      if handler
        element[event] = handler.bind(root)
      else
        element[event] = () -> context.eventChannel.publish( { control: fqn, event: event, context: context })

    copyProperties = ( source, target, list ) ->
      ( conditionalCopy source, target, x, list[x] ) for x in _.keys(list)

    conditionalCopy = ( source, target, sourceId, targetId ) ->
      val = source[sourceId]
      if val
        if _.isArray(targetId)
          ( target[x] = val ) for x in targetId
        else
          target[targetId] = val

    @map = (model) ->
        fn = crawl this, model, namespace, @element, @map
        fn @html, model

    this