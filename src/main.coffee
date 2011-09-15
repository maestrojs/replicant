
replicant =
  default:
    onGet: ( key, value ) -> console.log "read: #{key} -> #{value}"
    onSet: ( key, value, old ) -> console.log "wrote: #{key}. #{old} -> #{value}"
    namespace: ""

  create: ( target, get, set, namespace ) ->
    this.onGet = get or= this.default.onGet
    this.onSet = set or= this.default.onSet
    this.namespace = namespace or= this.default.namespace
    onProxyOf target,
    -> new ArrayProxy( target, onGet, onSet, namespace),
    -> new ObjectProxy( target, onGet, onSet, namespace ),
    -> target

context["replicant"] = replicant