ObjectWrapper = (target, onEvent, namespace, addChild, removeChild) ->
  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @addDependencyProperty = ( key, observable ) -> proxy.addDependencyProperty key, observable
  @extractAs = ( alias ) -> replicant.create proxy.original, null, alias
  @getOriginal = () -> proxy.original

  this

ArrayWrapper = (target, onEvent, namespace, addChild, removeChild) ->
  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @addDependencyProperty = ( key, observable ) -> proxy.addDependencyProperty key, observable
  @extractAs = ( alias ) -> replicant.create proxy.original, null, alias
  @getOriginal = () -> proxy.original
  @pop = -> proxy.pop()
  @push = (value) -> proxy.push value
  @shift = -> proxy.shift()
  @unshift = (value) -> proxy.unshift value

  this

Proxy = (wrapper, target, onEvent, namespace, addChild, removeChild) ->
  self = this
  fullPath = namespace or= ""
  addToParent = addChild or () ->

  getLocalPath = () ->
    parts = fullPath.split('.')
    if parts.length > 0 then parts[parts.length-1] else fullPath
  
  proxy = {}
  path = getLocalPath()
  removeFromParent = removeChild or () ->
  subject = target
  ancestors = []
  readHook = null

  addChildPath = ( lqn, child, key ) ->
    isRoot = ancestors.length == 0
    fqn = buildFqn path, lqn
    propertyName = if isRoot then fqn else lqn
    Object.defineProperty wrapper, propertyName,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    if child != wrapper and not _.any( child.ancestors, (x) -> x == wrapper )
      child.ancestors.push wrapper
    addToParent fqn, child, key

  @getHandler = () -> onEvent

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
    value = if value.getOriginal then value.getOriginal() else value
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        -> new ObjectWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        -> value
    proxy[key]

  createMemberProxy = (key) ->
    fqn = buildFqn path, key
    createProxyFor true, buildFqn( fullPath, key ), key
    
    Object.defineProperty wrapper, key,
      get: ->
        fqn1 = buildFqn fullPath, key
        value = createProxyFor(false, fqn1, key)
        notify fqn1, "read", { value: value }
        dependencyManager.recordAccess wrapper, fqn1
        value

      set: (value) ->
        fqn1 = buildFqn fullPath, key
        old = proxy[key]
        subject[key] = value
        newValue = createProxyFor(true, fqn1, key)
        notify fqn1, "wrote", { value: value, previous: old }

      configurable: true
      enumerable: true

    isRoot = ancestors.length == 0
    if isRoot and fullPath != ""
      addChildPath key, wrapper, key
    else
      addToParent fqn, wrapper, key

  Object.defineProperty wrapper, "length",
    get: ->
        fqn1 = buildFqn fullPath, "length"
        notify fqn1, "read", { value: subject.length }
        dependencyManager.recordAccess wrapper, fqn1
        subject.length

  Object.defineProperty wrapper, "ancestors",
    get: ->
        ancestors
    set: (x) ->
        ancestors = x
    enumerable: false
    configurable: true

  @addDependencyProperty = ( key, observable ) ->
    fqn1 = buildFqn fullPath, key
    dependencyManager.watchFor( fqn1 )
    observable(wrapper)
    dependencyManager.endWatch()

    Object.defineProperty wrapper, key,
      get: ->
        observable(wrapper)

    isRoot = ancestors.length == 0
    if isRoot and fullPath != ""
      addChildPath key, wrapper, key
    else
      addToParent buildFqn( path, key ), wrapper, key

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
          self.addDependencyProperty key, dependencyList[key]

  walk( target )

  addToParent ( buildFqn path, "length" ), wrapper, "length"

  this