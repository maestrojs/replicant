Replicant = () ->
  self = this
  proxies = {}

  add = (name, proxy) ->
    proxies[name] = proxy
    if not self[name]
      Object.defineProperty self, name,
        get: ->
          proxies[name]

  postal.channel("replicant").subscribe (m) ->
    if m.create
      self.create m.target, m.onevent, m.namespace
    else if m.get
      m.callback( proxies[m.name] )
    else
      _(proxies).each( (x) -> x.getChannel().publish m )

  @create = ( target, onevent, namespace ) ->
    dependencyManager.addNamespace namespace

    channel = postal.channel namespace + "_model"

    onEvent = onevent or= ( parent, key, event, info ) ->
      channel.publish { event: event, parent: parent, key: key, info: info }
    namespace = namespace or= ""
    
    proxy = onProxyOf target,
    -> new ArrayWrapper( target, onEvent, namespace ),
    -> new ObjectWrapper( target, onEvent, namespace ),
    -> target
    -> target

    proxy.subscribe namespace + "_events"
    add namespace, proxy
    proxy

  self

context["replicant"] = new Replicant()