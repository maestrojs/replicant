ObjectWrapper = (target, onEvent, namespace, addChild, removeChild) ->
  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @addDependencyProperty = ( key, observable ) -> proxy.addDependencyProperty key, observable
  @extractAs = ( alias ) -> replicant.create proxy.original, null, alias
  @getOriginal = () -> proxy.original
  @subscribe = ( channelName ) -> proxy.subscribe channelName
  @getPath = () -> proxy.getPath()
  @getChannel = () -> proxy.getChannel()

  this

ArrayWrapper = (target, onEvent, namespace, addChild, removeChild) ->
  proxy = new Proxy( this, target, onEvent, namespace, addChild, removeChild)

  @change_path = (p) -> proxy.change_path p
  @addDependencyProperty = ( key, observable ) -> proxy.addDependencyProperty key, observable
  @extractAs = ( alias ) -> replicant.create proxy.original, null, alias
  @getOriginal = () -> proxy.original
  @getPath = () -> proxy.getPath()
  @getChannel = () -> proxy.getChannel()
  @pop = -> proxy.pop()
  @push = (value) -> proxy.push value
  @shift = -> proxy.shift()
  @subscribe = ( channelName ) -> proxy.subscribe channelName
  @unshift = (value) -> proxy.unshift value
  @reverse = () -> proxy.reverse()
  @sort = (fn) -> proxy.sort(fn)
  @join = (separator) -> proxy.join(separator)
  @toString = () -> proxy.toString()
  @splice = () -> proxy.splice.apply(proxy,Array::slice.call(arguments, 0))

  this

Proxy = (wrapper, target, onEvent, namespace, addChild, removeChild) ->
  self = this
  fullPath = namespace or= ""
  addToParent = addChild or () ->

  getLocalPath = () ->
    parts = fullPath.split('.')
    if parts.length > 0 then parts[parts.length-1] else fullPath

  path = getLocalPath()
  proxy = {}
  removeFromParent = removeChild or () ->
  subject = target
  ancestors = []
  readHook = null
  proxySubscription = {}

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


  @subscribe = ( channelName ) ->
    if proxySubscription and proxySubscription.unsubscribe
      proxySubscription.unsubscribe()

    proxySubscription = postal.channel( channelName ).subscribe (m) ->
      if m.event == "onchange"
        wrapper[m.id] = m.control.value

  @getHandler = () -> onEvent

  createMemberProxy = (key) ->
    fqn = buildFqn path, key
    createProxyFor true, buildFqn( fullPath, key ), key

    Object.defineProperty wrapper, key,
      get: ->
        fqn1 = buildFqn fullPath, key
        value = createProxyFor(false, fqn1, key)
        notify fqn1, "read", { value: value }
        dependencyManager.recordAccess wrapper, fqn1
        unwindAncestralDependencies()
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

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    value = if value.getOriginal then value.getOriginal() else value
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        -> new ObjectWrapper( value, onEvent, fqn, addChildPath, removeChildPath ),
        -> value
    proxy[key]

  getLocalFqn = ( fqn ) ->
      parts = fqn.split "."
      base = subject.constructor.name
      result =
        switch parts.length
          when 0 then base
          else "#{base}.#{parts[parts.length-1]}"

  notify = ( key, event, info ) ->
    onEvent wrapper, key, event, info

  removeChildPath = (fqn) ->
    delete wrapper[fqn]
    removeFromParent fqn

  unwindAncestralDependencies = () ->
    _( ancestors )
      .chain().select( (x) -> x instanceof ArrayWrapper )
      .each( (x) -> dependencyManager.recordAccess x, "#{x.getPath}.length" )

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

  @change_path = (p) -> fullPath = p
  @getChannel = () -> proxySubscription
  @getHandler = () -> onEvent
  @getPath = () -> fullPath
  @original = subject

  @add = ( key, keys ) ->
    @recrawl keys
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
    @recrawl keys
    notify buildFqn( fullPath, "length"), "wrote", {
      value: subject.length,
      previous: 1 + subject.length
    }
    notify buildFqn(fullPath, key), "removed", {
      index: subject.length
      value: value
    }
    #TODO: remove console.logs when done
    console.log wrapper
    value

  @recrawl = (keys) ->
    createMemberProxy k for k in keys

  @genReadNotices = (keys) ->
    notify buildFqn(fullPath,k), "read", { value: wrapper[k] } for k in keys

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

  @reverse = ->
    old = wrapper
    subject.reverse()
    walk subject
    notify fullPath, "reversed", {
      index: subject.length
      value: wrapper
      previous: old
    }

  @sort = ->
    old = wrapper
    subject.sort.apply(subject, arguments)
    walk subject
    notify fullPath, "sorted", {
      index: subject.length
      value: wrapper
      previous: old
    }

  @join = ->
    value = subject.join.apply(subject, arguments)
    # TODO: we may want to change this to send ONE notice
    @genReadNotices [0..subject.length-1]
    value

  @toString = ->
    value = subject.toString.apply(subject, arguments)
    # TODO: we may want to change this to send ONE notice
    @genReadNotices [0..subject.length-1]
    value

  @indexOf = ->
    i = undefined
    value = undefined
    len = undefined
    if typeof x is "ObjectWrapper" or typeof x is "ArrayWrapper"
      len = wrapper.length
      while i < len
        if wrapper[i] is arguments[0]
          value = i
          break
        i++
    else
      value = subject.indexOf(x)

    notify buildFqn(fullPath, value), "read", {
      index: subject.length
      value: value
    }
    value

  @lastIndexOf = ->
    i = wrapper.length - 1
    value = undefined
    if typeof x is "ObjectWrapper" or typeof x is "ArrayWrapper"
      while i >= 0
        if wrapper[i] is arguments[0]
          value = i
          break
        i--
    else
      value = subject.indexOf(x)

    notify buildFqn(fullPath, value), "read", {
      index: subject.length
      value: value
    }
    value

  @splice = ->
    args = Array::slice.call(arguments, 0, 2)
    newItems = Array::slice.call(arguments, 2)
    len = newItems.length
    subjLen = subject.length
    value = undefined
    i = 0
    stIdx = 0
    while i < len
      if typeof newItems[i] is "ObjectWrapper" or typeof newItems[i] is "ArrayWrapper"
        newItems[i] = newItems[i].getOriginal()
      i++
    if args[0] >= 0
      stIdx = i = args[0]
    else
      stIdx = i = subject.length + args[0]
    chgLen = args[1] + args[0]
    while i <= subjLen
      removeChildPath i
      @remove i, wrapper[i], []  if i <= chgLen
      i++
    value = subject.splice.apply(subject, args.concat(newItems))
    @recrawl [stIdx..subject.length-1]
    replicant.create value, fullPath
    

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

    Object.defineProperty wrapper, key,
      get: ->
        dependencyManager.watchFor( fqn1 )
        result = observable(wrapper)
        dependencyManager.endWatch()
        result
        
    wrapper[key]

    isRoot = ancestors.length == 0
    if isRoot and fullPath != ""
      addChildPath key, wrapper, key
    else
      addToParent buildFqn( path, key ), wrapper, key

  walk( target )

  addToParent ( buildFqn path, "length" ), wrapper, "length"

  this