(function(context) {
/*
  replicant
  author: Alex Robson <@A_Robson>
  License: MIT ( http://www.opensource.org/licenses/mit-license )
  Version: 0.1.0
*/
var buildFqn, onProxyOf;
buildFqn = function(path, name) {
  if (path === "") {
    return name;
  } else {
    return "" + path + "." + name;
  }
};
onProxyOf = function(value, ifArray, ifObject, otherwise) {
  var isArray, isObject;
  isObject = _(value).isObject();
  isArray = _(value).isArray();
  if (isObject || isArray) {
    if (isArray) {
      return ifArray();
    } else {
      return ifObject();
    }
  } else {
    return otherwise();
  }
};
var ArrayProxy;
ArrayProxy = function(array, onGet, onSet, namespace, addChild, removeChild) {
  var addChildPath, addToParent, createIndex, getCallback, noOp, path, proxy, removeChildPath, removeFromParent, self, setCallback, subject;
  self = this;
  subject = array;
  proxy = {};
  path = namespace || "";
  noOp = function() {};
  self["name"] = "ArrayProxy";
  addToParent = addChild || noOp;
  removeFromParent = removeChild || noOp;
  addChildPath = function(fqn, child, key) {
    Object.defineProperty(self, fqn, {
      get: function() {
        return child[key];
      },
      set: function(value) {
        return child[key] = value;
      },
      configurable: true
    });
    return addToParent(fqn, child, key);
  };
  removeChildPath = function(fqn) {
    delete self[fqn];
    return removeFromParent(fqn);
  };
  getCallback = function(key, value) {
    console.log("Got " + key);
    return onGet(key, value);
  };
  setCallback = function(key, newValue, oldValue) {
    console.log("Set " + key);
    return onSet(key, newValue, oldValue);
  };
  createIndex = function(target, key) {
    var fqn, original;
    original = subject[key];
    fqn = buildFqn(path, key);
    addToParent(fqn, target[key]);
    target[key] = onProxyOf(original, function() {
      return new ArrayProxy(original, onGet, onSet, fqn, addChildPath, removeChildPath);
    }, function() {
      return new ObjectProxy(original, onGet, onSet, fqn, addChildPath, removeChildPath);
    }, function() {
      return original;
    });
    return Object.defineProperty(self, key, {
      get: function() {
        var value;
        value = target[key];
        getCallback(fqn, value);
        return value;
      },
      set: function(value) {
        var old;
        old = target[key];
        target[key] = value;
        subject[key] = value;
        return setCallback(fqn, value, old);
      },
      configurable: true,
      enumerable: true
    });
  };
  this.push = function(value) {
  var fqn, key;
  console.log("" + value + " was pushed");
  key = subject.length;
  subject.push(value);
  console.log("Creating proxy for " + key);
  createIndex(proxy, key);
  fqn = buildFqn(path, key);
  return setCallback(fqn, value, void 0);
};
this.unshift = function(value) {
  var fqn, key;
  subject.push(value);
  key = subject.length - 1;
  createIndex(proxy, key);
  fqn = buildFqn(path, key);
  return setCallback(fqn, value, subject[1]);
};
this.pop = function() {
  var fqn, key, value;
  value = subject.pop();
  key = subject.length - 1;
  fqn = buildFqn(path, key);
  setCallback(fqn, void 0, value);
  delete self[subject.length];
  return value;
};
this.shift = function() {
  var fqn, value;
  value = subject.shift();
  fqn = buildFqn(path, "0");
  setCallback(0, void 0, value);
  delete self[subject.length];
  return value;
};
  _(array).chain().keys().each(function(key) {
    return createIndex(proxy, key);
  });
  return self;
};
var ObjectProxy;
ObjectProxy = function(subject, onGet, onSet, namespace, addChild, removeChild) {
  var addChildPath, addToParent, createMemberProxy, createProxyFor, getCallback, lastAccessed, lastRead, lastSet, lastWritten, noOp, path, proxy, removeChildPath, removeFromParent, self, setCallback;
  self = this;
  lastRead = [];
  lastSet = [];
  proxy = {};
  path = namespace || "";
  noOp = function() {};
  addToParent = addChild || noOp;
  removeFromParent = removeChild || noOp;
  lastAccessed = function() {
    var list;
    list = lastRead;
    lastRead = [];
    return list;
  };
  lastWritten = function() {
    var list;
    list = lastSet;
    lastSet = [];
    return list;
  };
  self["name"] = "ObjectProxy";
  addChildPath = function(fqn, child, key) {
    Object.defineProperty(self, fqn, {
      get: function() {
        return child[key];
      },
      set: function(value) {
        return child[key] = value;
      },
      configurable: true
    });
    return addToParent(fqn, child, key);
  };
  removeChildPath = function(fqn) {
    delete self[fqn];
    return removeFromParent(fqn);
  };
  getCallback = function(key, value) {
    console.log("Got " + key + " of " + (typeof value));
    onGet(key, value);
    return lastRead.push(key);
  };
  setCallback = function(key, newValue, oldValue) {
    console.log("Set " + key);
    onSet(key, newValue, oldValue);
    return lastSet.push(key);
  };
  createProxyFor = function(writing, self, proxy, fqn, key) {
    var value;
    value = subject[key];
    if (writing || proxy[key] === void 0) {
      proxy[key] = onProxyOf(value, function() {
        return new ArrayProxy(value, onGet, onSet, fqn, addChildPath, removeChildPath);
      }, function() {
        return new ObjectProxy(value, onGet, onSet, fqn, addChildPath, removeChildPath);
      }, function() {
        return value;
      });
    }
    return proxy[key];
  };
  createMemberProxy = function(self, proxy, key) {
    var fqn;
    fqn = buildFqn(path, key);
    addChildPath(fqn, self, key);
    return Object.defineProperty(self, key, {
      get: function() {
        var value;
        value = createProxyFor(false, self, proxy, fqn, key);
        getCallback(fqn, value);
        return value;
      },
      set: function(value) {
        var newValue, old;
        old = proxy[key];
        subject[key] = value;
        newValue = createProxyFor(true, self, proxy, fqn, key);
        return setCallback(fqn, newValue, old);
      },
      configurable: true,
      enumerable: true
    });
  };
  _(subject).chain().keys().each(function(key) {
    return createMemberProxy(self, proxy, key);
  });
  return self;
};
var replicant;
replicant = {
  "default": {
    onGet: function(key, value) {
      return console.log("read: " + key + " -> " + value);
    },
    onSet: function(key, value, old) {
      return console.log("wrote: " + key + ". " + old + " -> " + value);
    },
    namespace: ""
  },
  create: function(target, get, set, namespace) {
    var onGet, onSet;
    onGet = get || (get = this["default"].onGet);
    onSet = set || (set = this["default"].onSet);
    namespace = namespace || (namespace = this["default"].namespace);
    return onProxyOf(target, function() {
      return new ArrayProxy(target, onGet, onSet, namespace);
    }, function() {
      return new ObjectProxy(target, onGet, onSet, namespace);
    }, function() {
      return target;
    });
  }
};
context["replicant"] = replicant;
})(window);