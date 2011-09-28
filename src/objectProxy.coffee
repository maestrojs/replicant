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

  @change_path = (p) ->
    path = p

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
    onGet self, key, value
    lastRead.push key

  setCallback = (key, newValue, oldValue) ->
    onSet self, key, newValue, oldValue
    lastSet.push key

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> new ObjectProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        ->
          _(value).chain().keys().each (k) ->
            addChildPath( "#{fqn}.#{k}", value, k )
            value.change_path( fqn )
          value
        ,
        -> value
    proxy[key]

  createMemberProxy = (self, proxy, key) ->
    fqn = buildFqn path, key
    if addToParent
        addToParent fqn, self, key
    else
        addChildPath fqn, self, key
    createProxyFor(false, fqn, key)
    
    Object.defineProperty self, key,
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

   Object.defineProperty self, "length",
    get: ->
        proxy.length

  _(subject).chain().keys().each (key) ->
    createMemberProxy self, proxy, key

  self