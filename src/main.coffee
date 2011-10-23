replicant =

  create: ( target, onevent, namespace ) ->
    dependencyManager.addNamespace namespace

    channel = postal.channel namespace + "_model"

    onEvent = onevent or= ( parent, key, event, info ) ->
      channel.publish { event: event, parent: parent, key: key, info: info }
    namespace = namespace or= ""
    
    proxy = onProxyOf target,
    -> new ArrayWrapper( target, onEvent, namespace),
    -> new ObjectWrapper( target, onEvent, namespace ),
    -> target
    -> target

    proxy.subscribe( namespace + "_events" )

    proxy

context["replicant"] = replicant