ObjectWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  
  this

ArrayWrapper = (target, onEvent, namespace, addChild, removeChild) ->

  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @push = (value) -> proxy.push value
  @unshift = (value) -> proxy.unshift value
  @pop = -> proxy.pop
  @shift = -> proxy.shift

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

  @push = (value) ->
    key = subject.length
    subject.push value
    createMemberProxy key
    fqn = buildFqn(path, key)
    newIndex = subject.length - 1
    notify fqn, "added", {
      index: newIndex
      value: wrapper[newIndex]
    }

  @unshift = (value) ->
    key = subject.length
    subject.push value
    createMemberProxy key
    fqn = buildFqn(path, key)
    notify fqn, "added", {
      index: 0
      value: wrapper[0]
    }

  @pop = ->
    value = wrapper[subject.length - 1]
    subject.pop()
    key = subject.length - 1
    fqn = buildFqn(path, key)
    delete wrapper[subject.length]
    notify fqn, "removed", {
      index: subject.length
      value: value
    }
    value

  @shift = ->
    value = wrapper[0]
    subject.shift()
    fqn = buildFqn(path, "0")
    delete wrapper[subject.length]
    notify fqn, "removed", {
      index: 0
      value: value
    }
    value

  addChildPath = (fqn, child, key) ->
    Object.defineProperty wrapper, fqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    if child != wrapper and not _.any( child.ancestors, (x) -> x == wrapper )
        child.ancestors.push wrapper
    addToParent fqn, child, key

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
    createProxyFor(false, fqn, key)
    
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

  _(target).chain().keys().each (key) ->
    createMemberProxy key

  this