  @push = (value) ->
    console.log "#{value} was pushed"
    key = subject.length
    subject.push value
    console.log "Creating proxy for #{key}"
    createIndex proxy, key
    fqn = buildFqn(path, key)
    setCallback fqn, value, undefined

  @unshift = (value) ->
    subject.push value
    key = subject.length - 1
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