
replicant =
  default:
    onGet: ( key, value ) -> console.log "read: #{key} -> #{value}"
    onSet: ( key, value, old ) -> console.log "wrote: #{key}. #{old} -> #{value}"
    namespace: ""

  create: ( target, get, set, namespace ) ->
    onGet = get or= this.default.onGet
    onSet = set or= this.default.onSet
    namespace = namespace or= this.default.namespace
    onProxyOf target,
    -> new ArrayProxy( target, onGet, onSet, namespace),
    -> new ObjectProxy( target, onGet, onSet, namespace ),
    -> target

  scan: ( target, namespace ) ->
    domFactory target, namespace

  map: ( target ) ->
    new Cartographer( target, "" )

context["replicant"] = replicant