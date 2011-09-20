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
    console.log "Got #{key}"
    onGet key, value

  setCallback = (key, newValue, oldValue) ->
    console.log "Set #{key}"
    onSet key, newValue, oldValue

  createIndex = ( target, key ) ->
    original = subject[key]
    fqn = buildFqn path, key
    addToParent fqn, target[key]
    target[key] = onProxyOf original,
      -> new ArrayProxy( original, onGet, onSet, fqn, addChildPath, removeChildPath ),
      -> new ObjectProxy( original, onGet, onSet, fqn, addChildPath, removeChildPath ),
      -> original
    Object.defineProperty self, key,
      get: ->
        value = target[key]
        getCallback fqn, value
        value
      set: (value) ->
        old = target[key]
        target[key] = value
        subject[key] = value
        setCallback fqn, value, old

      configurable: true
      enumerable: true

  ###import "arrayOps.coffee" ###
  
  _(array).chain().keys().each (key) ->
    createIndex( proxy, key )
  self