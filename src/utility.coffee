buildFqn = (path, name) ->
    (if path == "" then name else "#{path}.#{name}")

onProxyOf = ( value, ifArray, ifObject, otherwise ) ->
  isObject = _(value).isObject()
  isArray = _(value).isArray()
  isFunction = _(value).isFunction()
  if not isFunction and ( isObject or isArray )
    if isArray
        ifArray()
    else
        ifObject()
  else
    otherwise()