Dependency = ( context, key, dependencies ) ->
  self = this
  _(dependencies).chain().each (x) ->
    self[x] = true
  @add = ( dependency ) -> self[dependency] = true
  @isHit = ( fqn ) -> self[fqn]
  @key = key
  @target = context

  self

DependencyManager = ( ) ->
  dependencies = []
  watchingFor = null
  self = this

  addDependency = ( context, fqn, key ) ->
    dependency = _.detect(dependencies, (x) -> x.key == fqn )
    if dependency
      dependency.add key
    else
      dependency = new Dependency( context, fqn, [key] )
      dependencies.push( dependency )

  checkDependencies = ( channelName, key ) ->
    _(dependencies)
          .chain()
          .select( (x) -> x.isHit key )
          .each( (x) ->
            self[channelName].publish {
              event: "wrote",
              parent: x.target,
              key: x.key,
              info:
                value: x.target[x.key]
                previous: null
          } )

  notify = ( key, event, info ) ->
    onEvent wrapper, key, event, info

  @watchFor = (fqn) ->
    watchingFor = fqn

  @endWatch = () -> watchingFor = null

  @recordAccess = (proxy, key) ->
    if watchingFor
      addDependency proxy, watchingFor, key

  @addNamespace = ( namespace ) ->
    channelName = namespace + "_model"
    self[channelName] = postal.channel(channelName)
    self[channelName].subscribe (m) ->
      if m.event == "wrote" or m.event == "added" or m.event == "removed"
        checkDependencies channelName, m.key

  self

dependencyManager = new DependencyManager()