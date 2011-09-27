
replicant =
  default:
    onGet: ( key, value ) -> console.log "read: #{key} -> #{value}"
    onSet: ( key, value, old ) -> console.log "wrote: #{key}. #{old} -> #{value}"
    namespace: ""

  create: ( target, get, set, namespace ) ->
    channel = postal.channel namespace

    onGet = get or= ( key, value ) -> channel.publish { key: key, value: value }
    onSet = set or= ( key, value, old ) -> channel.publish { key: key, value: value, original: old }
    namespace = namespace or= this.default.namespace
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