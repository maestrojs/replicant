
replicant =
  default:
    onGet: ( parent, key, value ) -> console.log "read: #{key} -> #{value}"
    onSet: ( parent, key, value, old ) -> console.log "wrote: #{key}. #{old} -> #{value}"
    namespace: ""

  create: ( target, get, set, namespace ) ->
    channel = postal.channel namespace + "_model"

    onGet = get or= ( parent, key, value ) -> channel.publish { event: "read", parent: parent, key: key, value: value }
    onSet = set or= ( parent, key, value, old ) -> channel.publish { event: "wrote", parent: parent, key: key, value: value, original: old }
    namespace = namespace or= @default.namespace
    proxy = onProxyOf target,
    -> new ArrayProxy( target, onGet, onSet, namespace),
    -> new ObjectProxy( target, onGet, onSet, namespace ),
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