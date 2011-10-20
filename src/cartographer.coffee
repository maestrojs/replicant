Cartographer = (target, namespace) ->
    @element = $(target)[0]
    @map = ->
    @html = DOMBuilder.dom
    @template = {}

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

    subscribe = ( context ) ->
        postal.channel(context.fqn + "_model").subscribe (m) ->

            if m.event != "read"
              control = context[m.key]

              lastIndex = m.key.lastIndexOf "."
              parentKey = m.key.substring 0, lastIndex
              childKey = m.key.substring ( lastIndex + 1 )
              target = "value"

              if childKey == "value" or not control
                  control = context[parentKey]
                  target = childKey

              if m.event == "wrote"
                  if control
                      conditionalCopy m.info, control, "value", modelTargets[target]

              else if m.event == "added"
                addName = parentKey + "_add"
                newElement = context.template[addName]( childKey, m.parent )
                $(context[parentKey]).append newElement

    subscribe( this )

    eventHandlers =
      click: "onclick"
      dblclick: "ondblclick"
      mousedown: "onmousedown"
      mouseup: "onmouseup"
      mouseover: "onmouseover"
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
      title: "title"
      class: "className"
      value: ["value", "textContent"]

    modelTargetsForCollections =
      hide: "hidden"
      title: "title"
      value: "value"
      class: "className"

    templateProperties =
      id: "id"
      name: "name"
      title: "title"
      className: "class"
      type: "type"
      width: "width"
      height: "height"
      value: "value"

    crawl = ( context, root, namespace, element ) ->
        id = element["id"]
        fqn = createFqn namespace, id
        tag = element.tagName.toUpperCase()
        context = context or root

        if element.children != undefined and element.children.length > 0
            createChildren = ( crawl( context, root, fqn, child ) for child in element.children )

            call = ( html, model, parentFqn, idx ) ->
                actualId = if id == "" then idx else id
                myFqn = createFqn parentFqn, actualId
                val = if actualId == fqn or actualId == undefined then model else model?[actualId]
                collection = if val instanceof ArrayWrapper then val else val?.items
                if collection and collection instanceof ArrayWrapper
                    list = []
                    childFactory = createChildren[0]
                    context.template[myFqn + "_add"] = ( newIndex, newModel ) ->
                        childFactory( html, newModel, myFqn, newIndex )

                    for indx in [0..collection.length-1]
                        #list.push childFactory( html, collection, myFqn, indx )
                        list.push ( call( html, collection, myFqn, indx ) for call in createChildren )
                        
                    childElement = makeTag( context, html, tag, element, myFqn, actualId, list, root, model )
                    context[myFqn] = childElement
                    childElement
                else
                    controls = ( call( html, val, myFqn ) for call in createChildren )
                    childElement = makeTag( context, html, tag, element, myFqn, actualId, controls, root, model )
                    context[myFqn] = childElement
                    childElement

            context.template[fqn] = call
            call
        else
            call = ( html, model, parentFqn, idx ) ->
                actualId = if id == "" then idx else id
                myFqn = createFqn parentFqn, actualId
                val = if actualId == fqn then model else model?[actualId]
                childElement = makeTag( context, html, tag, element, myFqn, actualId, val, root, model )
                context[myFqn] = childElement
                childElement

            context.template[fqn] = call
            call

    makeTag = ( context, html, tag, template, myFqn, id, val, root, model ) ->
        properties = {}
        templateSource = if template.textContent then template.textContent else template.value
        content = if val then val else templateSource
        element = {}
        if id or id == 0
            properties.id = id

        if template
          copyProperties template, properties, templateProperties

        if tag == "INPUT"
            if not _.isObject content
              properties.value = content
            element = html[tag]( properties )
        else
          element = html[tag]( properties, content )
          
        if model?[id]
          if val instanceof Array
            copyProperties model[id], element, modelTargetsForCollections
          else
            copyProperties model[id], element, modelTargets
        setupEvents( model?[id], root, myFqn, element, context )
        element

    setupEvents = ( model, root, fqn, element, context ) ->
      if model
        (wireup x, eventHandlers[x], model, root, fqn, element, context ) for x in _.keys(eventHandlers)

    wireup = ( alias, event, model, root, fqn, element, context ) ->
      handler = model[alias]
      if handler
        handlerProxy = (x) -> handler.apply(
          model,
          [root, { id: fqn, control: context[fqn], event: event, context: context, info: x } ]
        )
        element[event] = handlerProxy
      else
        element[event] = (x) ->
            if event == "onchange"
                x.stopPropagation()
            context.eventChannel.publish( { id: fqn, model: model, control: context[fqn], event: event, context: context, info: x } )

    copyProperties = ( source, target, list ) ->
      ( conditionalCopy source, target, x, list[x] ) for x in _.keys(list)

    conditionalCopy = ( source, target, sourceId, targetId ) ->
      val = source[sourceId]
      if val != undefined and ( val != ""  )
        if _.isArray(targetId)
          ( target[x] = val ) for x in targetId
        else
          target[targetId] = val
          #console.log "Writing #{val} to #{targetId} of #{target}"

    @map = (model) ->
        fn = crawl this, model, namespace, @element, @map
        fn @html, model

    this