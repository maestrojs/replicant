ObjectProxy = (subject, onGet, onSet, namespace, addChild, removeChild) ->
  self = this
  lastRead = []
  lastSet = []
  proxy = {}
  path = namespace or ""
  noOp = ->
  addToParent = addChild or noOp
  removeFromParent = removeChild or noOp

  lastAccessed = ->
    list = lastRead
    lastRead = []
    list

  lastWritten = ->
    list = lastSet
    lastSet = []
    list

  addChildPath = (fqn, child, key) ->
    Object.defineProperty self, fqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    addToParent fqn, child, key

  removeChildPath = (fqn) ->
    delete self[fqn]
    removeFromParent fqn

  getCallback = (key, value) ->
    onGet key, value
    lastRead.push key

  setCallback = (key, newValue, oldValue) ->
    onSet key, newValue, oldValue
    lastSet.push key

  createProxyFor = ( writing, self, proxy, fqn, key, value ) ->
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> new ObjectProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> value
      value = proxy[key]
    value

  createMemberProxy = (self, proxy, key) ->
    fqn = buildFqn(path, key)
    addChildPath fqn, self, key
    Object.defineProperty self, key,
      get: ->
        value = subject[key]
        value = createProxyFor(false, self, proxy, fqn, key, value)
        getCallback fqn, value
        value

      set: (value) ->
        old = subject[key]
        subject[key] = value
        value = createProxyFor(true, self, proxy, fqn, key, value)
        setCallback fqn, value, old

      configurable: true
      enumerable: true

  _(subject).chain().keys().each (key) ->
    createMemberProxy self, proxy, key
  self