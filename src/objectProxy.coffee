ObjectProxy = (subject, onGet, onSet, namespace, addChild, removeChild) ->
  self = this
  lastRead = []
  lastSet = []
  proxy = {}
  path = namespace or= ""
  noOp = ->
  addToParent = addChild #or addChildPath
  removeFromParent = removeChild #or removeChildPath
  
  lastAccessed = ->
    list = lastRead
    lastRead = []
    list

  lastWritten = ->
    list = lastSet
    lastSet = []
    list

  self["name"] = "ObjectProxy"

  addChildPath = (fqn, child, key) ->
    Object.defineProperty self, fqn,
      get: -> child[key]
      set: (value) -> child[key] = value
      configurable: true
    if addToParent
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

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> new ObjectProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> value
    proxy[key]

  createMemberProxy = (self, proxy, key) ->
    fqn = buildFqn(path, key)
    if addToParent
        addToParent fqn, self, key
    else
        addChildPath fqn, self, key
    createProxyFor(false, fqn, key)
    
    Object.defineProperty self, key,
      get: ->
        value = createProxyFor(false, fqn, key)
        getCallback fqn, value
        value

      set: (value) ->
        old = proxy[key]
        subject[key] = value
        newValue = createProxyFor(true, fqn, key)
        setCallback fqn, newValue, old

      configurable: true
      enumerable: true

   Object.defineProperty self, "length",
    get: ->
        proxy.length

  _(subject).chain().keys().each (key) ->
    createMemberProxy self, proxy, key

  self