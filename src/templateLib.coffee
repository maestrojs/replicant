TemplateLibrary = (root) ->
    rootPath = root

    amplify.request.define( "templateLoader", "ajax",
        {
            url: "{root}/{template}",
            dataType: "",
            type: "GET"
        })

    @getTemplate: (name, onLoad) ->
        amplify.request( "templateLoader",
            { template: name, root: rootPath },
            (data) ->
                onLoad data
        )
