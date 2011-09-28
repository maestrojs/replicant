  @push = (value) ->
    key = subject.length
    subject.push value
    createIndex key
    fqn = buildFqn(path, key)
    setCallback fqn, self[subject.length - 1], undefined

  @unshift = (value) ->
    key = subject.length
    subject.push value
    createIndex proxy, key
    fqn = buildFqn(path, key)
    setCallback fqn, self[0], self[1]

  @pop = ->
    value = self[subject.length - 1]
    subject.pop()
    key = subject.length - 1
    fqn = buildFqn(path, key)
    setCallback fqn, undefined, value
    delete self[subject.length]
    value

  @shift = ->
    value = self[0]
    subject.shift()
    fqn = buildFqn(path, "0")
    setCallback 0, undefined, value
    delete self[subject.length]
    value