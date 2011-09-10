var Proksy = function(
    subject,
    onGet,
    onSet,
    namespace,
    addChild,
    removeChild) {

    var self = this;
    var lastRead = [];
    var lastSet = [];
    var proxy = {};
    var path = namespace || "";

    var addToParent = addChild || function() {};

    var removeFromParent = removeChild || function() {};

    var buildFqn = function( path, name ) {
        return path === "" ? name : path + "." + name;
    };

    var lastAccessed = function() {
        var list = lastRead;
        lastRead = [];
        return list; 
    };

    var lastWritten = function() {
        var list = lastSet;
        lastSet = [];
        return list;
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
        lastRead.push( key );
    };

    var setCallback = function( key, newValue, oldValue ) {
        onSet( key, newValue, oldValue );
        lastSet.push( key );
    };

    var createProxyFor = function( writing, self, proxy, fqn, key, value ) {
        var isObject = _(value).isObject();
        var isArray = _(value).isArray();
        if( isObject || isArray ) {
            if( writing || proxy[key] === undefined ) {
                proxy[key] = isArray ?
                    new ArrayProksy( value, onGet, onSet, fqn, addChildPath, removeChildPath )
                    : new Proksy( value, onGet, onSet, fqn, addChildPath, removeChildPath );
            }
            value = proxy[key];
        }
        return value;
    };

    var createMemberProxy = function( self, proxy, key ) {

           var fqn = buildFqn( path, key );
           addChildPath( fqn, self, key );

           Object.defineProperty( self, key,
              {
                  get: function() {
                    var value = subject[key];
                    value = createProxyFor( false, self, proxy, fqn, key, value );
                    getCallback( fqn, value );
                    return value;
                  },
                  set: function(value) {
                    var old = subject[key];
                    subject[key] = value;
                    value = createProxyFor( true, self, proxy, fqn, key, value );
                    setCallback( fqn, value, old );
                  },
                  configurable: true,
                  enumerable: true
           });
       };

    _(subject)
       .chain()
       .keys()
       .each( function( key ) { createMemberProxy( self, proxy, key ); } );
};
