ObjectWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p

  @getOriginal = () -> proxy.original

  this

ArrayWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @push = (value) -> proxy.push value
  @unshift = (value) -> proxy.unshift value
  @pop = -> proxy.pop()
  @shift = -> proxy.shift()

  @getOriginal = () -> proxy.original

  this

Proxy = (wrapper, target, onEvent, namespace, addChild, removeChild) ->

  proxy = {}
  path = namespace or= ""
  addToParent = addChild or () ->
  removeFromParent = removeChild or () ->
  subject = target
  ancestors = []
  
  @change_path = (p) ->
    path = p

  @add = ( key, keys ) ->
    createMemberProxy k for k in keys
    notify buildFqn(path, key), "added", {
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
    notify buildFqn(path, key), "removed", {
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

  addChildPath = (fqn, child, key) ->
    Object.defineProperty wrapper, fqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    if child != wrapper and not _.any( child.ancestors, (x) -> x == wrapper )
        child.ancestors.push wrapper
    addToParent fqn, child, key

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
            addChildPath( "#{fqn}.#{k}", value, k )
            value.change_path( fqn )
          value
        ,
        -> value
    proxy[key]

  createMemberProxy = (key) ->
    fqn = buildFqn path, key
    addChildPath fqn, wrapper, key
    createProxyFor(true, fqn, key)
    
    Object.defineProperty wrapper, key,
      get: ->
        fqn1 = buildFqn path, key
        value = createProxyFor(false, fqn1, key)
        notify fqn1, "read", { value: value }
        value

      set: (value) ->
        fqn1 = buildFqn path, key
        old = proxy[key]
        subject[key] = value
        newValue = createProxyFor(true, fqn1, key)
        notify fqn1, "wrote", { value: value, previous: old }

      configurable: true
      enumerable: true

  Object.defineProperty wrapper, "length",
    get: ->
        subject.length
        
  Object.defineProperty wrapper, "ancestors",
    get: ->
        ancestors
    set: (x) ->
        ancestors = x
    enumerable: false
    configurable: true

  walk = (target) ->
      _(target).chain().keys().each (key) ->
        createMemberProxy key

  walk( target )

  this