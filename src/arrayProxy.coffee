ArrayProxy = (array, onGet, onSet, namespace, addChild, removeChild) ->
  self = this
  subject = array
  proxy = {}
  path = namespace or ""
  noOp = ->

  self["name"] = "ArrayProxy"

  @change_path = (p) ->
    path = p
  
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
    onGet self, key, value

  setCallback = (key, newValue, oldValue) ->
    onSet self, key, newValue, oldValue

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

  createIndex = ( key ) ->
    fqn = buildFqn path, key
    addToParent fqn, proxy[key]
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
        subject.length

  ###import "arrayOps.coffee" ###
  
  _(array).chain().keys().each (key) ->
    createIndex( key )
  self