ArrayProxy = (array, onGet, onSet, namespace, addChild, removeChild) ->
  self = this
  subject = array
  proxy = {}
  path = namespace or ""
  noOp = ->

  self["name"] = "ArrayProxy"
  
  addToParent = addChild or noOp
  removeFromParent = removeChild or noOp

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

  setCallback = (key, newValue, oldValue) ->
    onSet key, newValue, oldValue

  createProxyFor = ( writing, fqn, key ) ->
    value = subject[key]
    if writing or proxy[key] == undefined
      proxy[key] = onProxyOf value,
        -> new ArrayProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> new ObjectProxy( value, onGet, onSet, fqn, addChildPath, removeChildPath ),
        -> value
    proxy[key]

  createIndex = ( key ) ->
    fqn = buildFqn path, key
    addToParent fqn, proxy[key]
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
        subject.length

  ###import "arrayOps.coffee" ###
  
  _(array).chain().keys().each (key) ->
    createIndex( key )
  self