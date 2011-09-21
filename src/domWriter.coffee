domFactory = ( target, namespace ) ->
    switch target[0].tagName.toLowerCase()
        when "div" new DivProxy target, namespace
        when "span" new SpanProxy target, namespace
        when "input" new InputProxy target, namespace
        when "ul" new UlProxy target, namespace
        when "li" new LiProxy target, namespace

class DomProxy
    constructor (target, @namespace) ->
        self = this
        template = @namespace
        @element = target[0]

        self.crawl "", @element, ( @namespace, key, child ) ->
            prefix = template + ".";
            member = if @namespace === template then
                @namespace else @namespace.replace prefix, "", "gi"
            self[member] = domFactory child, member

    coalesce: ( value, defaultValue ) ->
        if typeof(value) != 'undefined' then value else defaultValue

    crawl: ( namespace, element, callback ) ->
        id = coalesce element["id"], ""
        fqn = buildFqn namespace, id
        callback fqn, id, element
        if element.children !== undefined and
            element.children.length > 0
            _(element.children)
                .chain()
                .each ( child ) ->
                        crawl fqn, child, callback

class DivProxy extends DomProxy

    write: ( path, value ) ->
        if path == @namespace
            if _.isObject( value )
                self.crawl "", value, ( @namespace, key, child ) ->
                    self.write( buildFqn( @namespace, key ), child )
            else
                $(@element).text( value )
        else
            proxy = self[path]
            proxy.write path, value


class SpanProxy extends DomProxy

    write: ( path, value ) ->
        if path == @namespace
            $(@element).text( value )
        else
            proxy = self[path]
            proxy.write path, value


class InputProxy extends DomProxy

    write: ( path, value ) ->
        if path == @namespace
            $(@element).val( value )
        else
            proxy = self[path]
            proxy.write path, value


class UlProxy extends DomProxy

    write: ( path, value ) ->
        if path == @namespace
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
            proxy = self[path]
            proxy.write path, value

class LiProxy extends DomProxy

    write: ( path, value ) ->
        if path == @namespace
            $(@element).text( value )