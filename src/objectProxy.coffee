ObjectWrapper = (target, onGet, onSet, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onGet, onSet, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  
  this

ArrayWrapper = (target, onGet, onSet, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onGet, onSet, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @push = (value) -> proxy.push value
  @unshift = (value) -> proxy.unshift value
  @pop = -> proxy.pop
  @shift = -> proxy.shift



  this

Proxy = (wrapper, target, onGet, onSet, namespace, addChild, removeChild) ->

  proxy = {}
  path = namespace or= ""
  addToParent = addChild or () ->
  removeFromParent = removeChild or () ->
  subject = target
  
  @change_path = (p) ->
    path = p

  @push = (value) ->
    key = subject.length
    subject.push value
    createMemberProxy key
    fqn = buildFqn(path, key)
    setCallback fqn, wrapper[subject.length - 1], undefined

  @unshift = (value) ->
    key = subject.length
    subject.push value
    createMemberProxy key
    fqn = buildFqn(path, key)
    setCallback fqn, wrapper[0], wrapper[1]

  @pop = ->
    value = wrapper[subject.length - 1]
    subject.pop()
    key = subject.length - 1
    fqn = buildFqn(path, key)
    setCallback fqn, undefined, value
    delete wrapper[subject.length]
    value

  @shift = ->
    value = wrapper[0]
    subject.shift()
    fqn = buildFqn(path, "0")
    setCallback 0, undefined, value
    delete wrapper[subject.length]
    value

  addChildPath = (fqn, child, key) ->
    Object.defineProperty wrapper, fqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    addToParent fqn, child, key

  removeChildPath = (fqn) ->
    delete wrapper[fqn]
    removeFromParent fqn

  getCallback = (key, value) ->
    onGet wrapper, key, value

  setCallback = (key, newValue, oldValue) ->
    onSet wrapper, key, newValue, oldValue

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayWrapper( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> new ObjectWrapper( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
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
    createProxyFor(false, fqn, key)
    
    Object.defineProperty wrapper, key,
      get: ->
        fqn1 = buildFqn path, key
        value = createProxyFor(false, fqn1, key)
        getCallback fqn1, value
        value

      set: (value) ->
        fqn1 = buildFqn path, key
        old = proxy[key]
        subject[key] = value
        newValue = createProxyFor(true, fqn1, key)
        setCallback fqn1, newValue, old

      configurable: true
      enumerable: true

  Object.defineProperty wrapper, "length",
    get: ->
        subject.length

  _(target).chain().keys().each (key) ->
    createMemberProxy key

  this