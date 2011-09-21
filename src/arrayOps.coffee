  @push = (value) ->
    key = subject.length
    subject.push value
    createIndex key
    fqn = buildFqn(path, key)
    setCallback fqn, value, undefined

  @unshift = (value) ->
    key = subject.length
    subject.push value
    createIndex proxy, key
    fqn = buildFqn(path, key)
    setCallback fqn, value, subject[1]

  @pop = ->
    value = subject.pop()
    key = subject.length - 1
    fqn = buildFqn(path, key)
    setCallback fqn, undefined, value
    delete self[subject.length]
    value

  @shift = ->
    value = subject.shift()
    fqn = buildFqn(path, "0")
    setCallback 0, undefined, value
    delete self[subject.length]
    value