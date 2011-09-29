
replicant =
  create: ( target, onevent, namespace ) ->
    channel = postal.channel namespace + "_model"

    onEvent = onevent or= ( parent, key, event, info ) ->
      channel.publish { event: event, parent: parent, key: key, info: info }
    namespace = namespace or= ""
    
    proxy = onProxyOf target,
    -> new ArrayWrapper( target, onEvent, namespace),
    -> new ObjectWrapper( target, onEvent, namespace ),
    -> target
    -> target

    postal.channel(namespace + "_events").subscribe (m) ->
      if m.event == "onchange"
        proxy[m.control] = m.context[m.control].value

    proxy

  scan: ( target, namespace ) ->
    domFactory target, namespace

  map: ( target ) ->
    new Cartographer( target, "" )

context["replicant"] = replicant