ArrayProxy = (array, onGet, onSet, namespace, addChild, removeChild) ->
  self = this
  subject = array
  proxy = {}
  path = namespace or ""
  noOp = ->

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

  getCallback = (key, value) -> onGet key, value

  setCallback = (key, newValue, oldValue) -> onSet key, newValue, oldValue

  createIndex = ( proxy, key ) ->
    original = subject[key]
    fqn = buildFqn path, key
    addToParent fqn, proxy[key]
    proxy[key] = onProxyOf original,
      -> new ArrayProxy( original, onGet, onSet, fqn, addChildPath, removeChildPath ),
      -> new ObjectProxy( original, onGet, onSet, fqn, addChildPath, removeChildPath ),
      -> original
    Object.defineProperty self, key,
      get: ->
        value = proxy[key]
        getCallback fqn, value
        value
      set: ->
        old = proxy[key]
        proxy[key] = value
        setCallback fqn, value, old

      configurable: true
      enumerable: true

  ###import "arrayOps.coffee" ###
  
  _(array).chain().keys().each (key) ->
    createIndex( proxy, key )