buildFqn = (path, name) ->
    (if path == "" then name else "#{path}.#{name}")

onProxyOf = ( value, ifArray, ifObject, absorb, otherwise ) ->
  isObject = _(value).isObject()
  isArray = _(value).isArray()
  isFunction = _(value).isFunction()
  isProxied = value instanceof ObjectProxy or value instanceof ArrayProxy
  if isProxied
    absorb()
  else if not isFunction and ( isObject or isArray )
    if isArray
        ifArray()
    else
        ifObject()
  else
    otherwise()