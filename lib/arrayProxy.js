var ArrayProksy = function(
    array,
    onGet,
    onSet,
    namespace,
    addChild,
    removeChild ) {

    var self = this;
    var subject = array;
    var proxy = {};
    var path = namespace || "";

    var addToParent = addChild || function() {};

    var removeFromParent = removeChild || function() {};

    var buildFqn = function( path, name ) {
        return path === "" ? name : path + "." + name;
    };

    var addChildPath = function( fqn, child, key ) {
        Object.defineProperty( self, fqn,
                               {
                                   get: function() {
                                       return child[key];
                                   },
                                   set: function( value ) {
                                       child[key] = value;
                                   },
                                   configurable: true
                               });
        addToParent( fqn, child, key );
    };

    var removeChildPath = function( fqn ) {
        delete self[fqn];
        removeFromParent( fqn );
    };

    var getCallback = function( key, value ) {
        onGet( key, value );
    };

    var setCallback = function( key, newValue, oldValue ) {
        onSet( key, newValue, oldValue );
    };

    var createIndex = function( proxy, key ) {
        var original = subject[key];
        var isObject = _(original ).isObject();
        var isArray = _(original ).isArray();
        var fqn = buildFqn( path, key );
        addToParent( fqn, proxy[key] );
        if( isObject || isArray ) {
           proxy[key] = isArray ?
                  new ArrayProksy( original , onGet, onSet, fqn, addChildPath, removeChildPath )
                : new Proksy( original , onGet, onSet, fqn, addChildPath, removeChildPath );
        }
        else {
            proxy[key] = original;
        }

        Object.defineProperty( self, key,
              {
                  get: function() {
                    var value = proxy[key];
                    getCallback( fqn, value );
                    return value;
                  },
                  set: function(value) {
                    var old = proxy[key];
                    proxy[key] = value;
                    setCallback( fqn, value, old );
                  },
                  configurable: true,
                  enumerable: true
           });
    };

    this.push = function( value ) {
        subject.push( value );
        var key = subject.length - 1;
        createIndex( proxy, key );
        var fqn = buildFqn( path, key );
        setCallback( fqn, value, undefined );
    };

    this.unshift = function( value ) {
        subject.push( value );
        var key = subject.length - 1;
        createIndex( proxy, key );
        var fqn = buildFqn( path, key );
        setCallback( fqn, value, subject[1] );
    };

    this.pop = function() {
        var value = subject.pop();
        var key = subject.length - 1;
        var fqn = buildFqn( path, key );
        setCallback( fqn, undefined, value );
        delete self[ subject.length ];
        return value;
    };

    this.shift = function() {
        var value = subject.shift();
        var fqn = buildFqn( path, "0" );
        setCallback( 0, undefined, value );
        delete self[ subject.length ];
        return value;
    };

    _(array)
        .chain()
        .keys()
        .each( function( key ) {
            createIndex( proxy, key );
        });

};