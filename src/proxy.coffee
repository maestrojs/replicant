Dependency = ( context, key, dependencies ) ->
  self = this
  _(dependencies).chain().each (x) ->
    self[x] = true
  @add = ( dependency ) -> self[dependency] = true
  @isHit = ( fqn ) -> self[fqn]
  @key = key
  @target = context

  self

DependencyListener = ( ) ->
  dependencies = []
  watchingFor = null
  self = this

  addDependency = ( context, fqn, key ) ->
    dependency = _.detect(dependencies, (x) -> x.key == fqn )
    if dependency
      dependency.add key
    else
      dependency = new Dependency( context, fqn, [key] )
      dependencies.push( dependency )

  checkDependencies = ( channelName, key ) ->
    _(dependencies)
          .chain()
          .select( (x) -> x.isHit key )
          .each( (x) ->
            self[channelName].publish {
              event: "wrote",
              parent: x.target,
              key: x.key,
              info:
                value: x.target[x.key]
                previous: null
          } )

  notify = ( key, event, info ) ->
    onEvent wrapper, key, event, info

  @watchFor = (fqn) ->
    watchingFor = fqn

  @endWatch = () -> watchingFor = null

  @recordAccess = (proxy, key) ->
    if watchingFor
      addDependency proxy, watchingFor, key

  @addNamespace = ( namespace ) ->
    channelName = namespace + "_model"
    self[channelName] = postal.channel(channelName)
    self[channelName].subscribe (m) ->
      if m.event == "wrote" or m.event == "added" or m.event == "removed"
        checkDependencies channelName, m.key

  self

dependencyListener = new DependencyListener()

ObjectWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p

  @defineObservable = ( key, observable ) -> proxy.defineObservable key, observable

  @extractAs = ( namespace ) ->
    replicant.create proxy.original, proxy.eventHandler, namespace

  @getOriginal = () -> proxy.original

  this

ArrayWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @push = (value) -> proxy.push value
  @unshift = (value) -> proxy.unshift value
  @pop = -> proxy.pop()
  @shift = -> proxy.shift()

  @defineObservable = ( key, observable ) -> proxy.defineObservable key, observable

  @extractAs = ( namespace ) ->
    replicant.create proxy.original, proxy.eventHandler, namespace

  @getOriginal = () -> proxy.original

  this

Proxy = (wrapper, target, onEvent, namespace, addChild, removeChild) ->
  self = this
  fullPath = namespace or= ""
  addToParent = null

  addChildPath = ( lqn, child, key ) ->
    isRoot = ancestors.length == 0
    head = if isRoot then fullPath else path
    fqn = buildFqn head, lqn
    lqn = if isRoot then fqn else lqn
    Object.defineProperty wrapper, lqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    if child != wrapper and not _.any( child.ancestors, (x) -> x == wrapper )
      child.ancestors.push wrapper
    if not isRoot
      addToParent fqn, child, lqn

  addToParent = addChild or addChildPath

  getLocalPath = () ->
    parts = fullPath.split('.')
    if parts.length > 0 then parts[parts.length-1] else ""
  
  proxy = {}
  path = getLocalPath()
  removeFromParent = removeChild or () ->
  subject = target
  ancestors = []
  readHook = null

  @eventHandler = onEvent

  @change_path = (p) ->
    fullPath = p

  @add = ( key, keys ) ->
    createMemberProxy k for k in keys
    notify buildFqn( fullPath, "length"), "wrote", {
      value: subject.length,
      previous: -1 + subject.length
    }
    notify buildFqn(fullPath, key), "added", {
      index: key
      value: wrapper[key]
    }

  @push = (value) ->
    key = -1 + subject.push value
    @add key, [key]

  @unshift = (value) ->
    subject.unshift value
    @add 0, [0..subject.length-1]

  @remove = ( key, value, keys ) ->
    createMemberProxy k for k in keys
    notify buildFqn( fullPath, "length"), "wrote", {
      value: subject.length,
      previous: 1 + subject.length
    }
    notify buildFqn(fullPath, key), "removed", {
      index: subject.length
      value: value
    }
    console.log wrapper
    value

  @original = subject

  @pop = ->
    key = subject.length - 1
    value = wrapper[key]
    subject.pop()
    removeChildPath key
    @remove key, value, []

  @shift = ->
    key = 0
    value = wrapper[key]
    subject.shift()
    removeChildPath key
    @remove key, value, [0..subject.length-1]

  getLocalFqn = ( fqn ) ->
      parts = fqn.split "."
      base = subject.constructor.name
      result =
        switch parts.length
          when 0 then base
          else "#{base}.#{parts[parts.length-1]}"

  removeChildPath = (fqn) ->
    delete wrapper[fqn]
    removeFromParent fqn

  notify = ( key, event, info ) ->
    onEvent wrapper, key, event, info

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        -> new ObjectWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        ->
          _(value).chain().keys().each (k) ->
            addToParent buildFqn( path, k ), value, k
            value.change_path( fqn )
          value
        ,
        -> value
    proxy[key]

  createMemberProxy = (key) ->
    fqn = buildFqn path, key
    addToParent fqn, wrapper, key
    createProxyFor true, buildFqn( fullPath, key ), key
    
    Object.defineProperty wrapper, key,
      get: ->
        fqn1 = buildFqn fullPath, key
        value = createProxyFor(false, fqn1, key)
        notify fqn1, "read", { value: value }
        dependencyListener.recordAccess wrapper, fqn
        value

      set: (value) ->
        fqn1 = buildFqn fullPath, key
        old = proxy[key]
        subject[key] = value
        newValue = createProxyFor(true, fqn1, key)
        notify fqn1, "wrote", { value: value, previous: old }

      configurable: true
      enumerable: true

  Object.defineProperty wrapper, "length",
    get: ->
        fqn1 = buildFqn fullPath, "length"
        notify fqn1, "read", { value: subject.length }
        dependencyListener.recordAccess wrapper, fqn1
        subject.length

  Object.defineProperty wrapper, "ancestors",
    get: ->
        ancestors
    set: (x) ->
        ancestors = x
    enumerable: false
    configurable: true

  @defineObservable = ( key, observable ) ->
    fqn1 = buildFqn fullPath, key
    dependencyListener.watchFor( fqn1 )
    observable(wrapper)
    dependencyListener.endWatch()
    addToParent buildFqn( path, key ), wrapper, key

    Object.defineProperty wrapper, key,
      get: ->
        observable(wrapper)

  walk = (target) ->
      _(target)
        .chain()
        .keys()
        .select( (x) -> x != "__dependencies__")
        .each (key) ->
          createMemberProxy key

      dependencyList = target.__dependencies__
      if dependencyList
        _(dependencyList)
        .chain()
        .keys()
        .each (key) ->
          self.defineObservable key, dependencyList[key]

  walk( target )

  addToParent ( buildFqn path, "length" ), wrapper, "length"

  this