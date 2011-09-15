buildFqn = (path, name) ->
    (if path == "" then name else "#{path}.#{name}")