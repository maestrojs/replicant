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
    onEvent = ( parent, key, event, info ) ->
      channel.publish { event: event, parent: parent, key: key, info: info }
    nmspc = ""

    if arguments.length is 2
      if typeof arguments[1] is "function"
        onEvent = onevent
      else
        nmspc = onevent
    else if arguments.length is 3
      onEvent = onevent
      nmspc = namespace

    dependencyManager.addNamespace nmspc

    channel = postal.channel nmspc + "_model"
    
    proxy = onProxyOf target,
    -> new ArrayWrapper( target, onEvent, nmspc ),
    -> new ObjectWrapper( target, onEvent, nmspc ),
    -> target
    -> target

    proxy.subscribe nmspc + "_events"
    add nmspc, proxy
    proxy

  self

context["replicant"] = new Replicant()