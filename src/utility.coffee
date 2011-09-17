buildFqn = (path, name) ->
    (if path == "" then name else "#{path}.#{name}")

onProxyOf = ( value, ifArray, ifObject, otherwise ) ->
  isObject = _(value).isObject()
  isArray = _(value).isArray()
  if isObject or isArray
    if isArray then ifArray() else ifObject()
  else
    otherwise()