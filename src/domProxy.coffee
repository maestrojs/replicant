class DomProxy
    constructor: (target, namespace) ->
        @element = target
        @fqn = if namespace == "" or namespace == undefined
                @element["id"]
              else
                buildFqn namespace, @element["id"]
        this.crawl this, @fqn, @element, this.crawl, this.addChild
        this

    addChild: ( context, namespace, key, child ) ->
        member = buildFqn namespace, key
        context[member] = domFactory child, namespace

    crawl: ( context, namespace, element, crawl, callback ) ->
        if element.children != undefined and element.children.length > 0
            _(element.children)
                .chain()
                .each ( child ) ->
                    callback context, namespace, child["id"], child
                    crawl context, namespace, child, crawl, callback

class DivProxy extends DomProxy

    write: ( path, value ) ->
        if path == @fqn
            if _.isObject( value )
                #this[x].write( value[x] ) for x in value
                for x in value
                    this[x].write value[x]
            else
                $(@element).text( value )
        else
            proxy = this[path]
            proxy.write path, value


class SpanProxy extends DomProxy

    write: ( path, value ) ->
        if path == @fqn
            $(@element).text( value )
        else
            proxy = this[path]
            proxy.write path, value


class InputProxy extends DomProxy

    write: ( path, value ) ->
        if path == @fqn
            $(@element).val( value )
        else
            proxy = this[path]
            proxy.write path, value


class UlProxy extends DomProxy

    write: ( path, value ) ->
        if path == @fqn
            children = $(@element).children("li")
            if children.length < value.length
                li = children[0];
                indx = 0;
                _(value)
                    .each ( child ) ->
                        newLi = $(li)
                            .clone()
                            .attr( "id", indx )
                            .appendTo( element )
                        self[ fqn + "." + indx ] = newLi[0]
                        indx++
        else
            proxy = this[path]
            proxy.write path, value

class LiProxy extends DomProxy

    write: ( path, value ) ->
        if path == @fqn
            $(@element).text( value )

domFactory = ( target, namespace ) ->
    this["div"] = ( target, namespace ) -> new DivProxy( target, namespace )
    this["span"] = ( target, namespace ) -> new SpanProxy( target, namespace )
    this["input"] = ( target, namespace ) -> new InputProxy( target, namespace )
    this["ul"] = ( target, namespace ) -> new UlProxy( target, namespace )
    this["li"] = ( target, namespace ) -> new LiProxy( target, namespace )

    if _.isString target
        element = $(target)[0]
        return this[element.tagName.toLowerCase()]( element, namespace )
    else
        return this[target.tagName.toLowerCase()]( target, namespace )