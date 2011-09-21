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
  var addChildPath, addToParent, createIndex, createProxyFor, getCallback, noOp, path, proxy, removeChildPath, removeFromParent, self, setCallback, subject;
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
    return onGet(key, value);
  };
  setCallback = function(key, newValue, oldValue) {
    return onSet(key, newValue, oldValue);
  };
  createProxyFor = function(writing, fqn, key) {
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
  createIndex = function(key) {
    var fqn;
    fqn = buildFqn(path, key);
    addToParent(fqn, proxy[key]);
    createProxyFor(false, fqn, key);
    return Object.defineProperty(self, key, {
      get: function() {
        var value;
        value = createProxyFor(false, fqn, key);
        getCallback(fqn, value);
        return value;
      },
      set: function(value) {
        var newValue, old;
        old = proxy[key];
        subject[key] = value;
        newValue = createProxyFor(true, fqn, key);
        return setCallback(fqn, newValue, old);
      },
      configurable: true,
      enumerable: true
    });
  };
  Object.defineProperty(self, "length", {
    get: function() {
      return subject.length;
    }
  });
  this.push = function(value) {
  var fqn, key;
  key = subject.length;
  subject.push(value);
  createIndex(key);
  fqn = buildFqn(path, key);
  return setCallback(fqn, value, void 0);
};
this.unshift = function(value) {
  var fqn, key;
  key = subject.length;
  subject.push(value);
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
    return createIndex(key);
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
    onGet(key, value);
    return lastRead.push(key);
  };
  setCallback = function(key, newValue, oldValue) {
    onSet(key, newValue, oldValue);
    return lastSet.push(key);
  };
  createProxyFor = function(writing, fqn, key) {
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
    addToParent(fqn, self, key);
    createProxyFor(false, fqn, key);
    return Object.defineProperty(self, key, {
      get: function() {
        var value;
        value = createProxyFor(false, fqn, key);
        getCallback(fqn, value);
        return value;
      },
      set: function(value) {
        var newValue, old;
        old = proxy[key];
        subject[key] = value;
        newValue = createProxyFor(true, fqn, key);
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
var DivProxy, DomProxy, InputProxy, LiProxy, SpanProxy, UlProxy, domFactory;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
DomProxy = (function() {
  function DomProxy(target, namespace) {
    var self, template;
    this.namespace = namespace;
    self = this;
    template = this.namespace;
    this.element = target[0];
    self.crawl("", this.element, function(namespace, key, child) {
      var member, prefix;
      this.namespace = namespace;
      prefix = template + ".";
      member = this.namespace === template ? this.namespace : this.namespace.replace(prefix, "", "gi");
      return self[member] = domFactory(child, member);
    });
  }
  DomProxy.prototype.coalesce = function(value, defaultValue) {
    if (typeof value !== 'undefined') {
      return value;
    } else {
      return defaultValue;
    }
  };
  DomProxy.prototype.crawl = function(namespace, element, callback) {
    var fqn, id;
    id = coalesce(element["id"], "");
    fqn = buildFqn(namespace, id);
    callback(fqn, id, element);
    if (element.children !== void 0 && element.children.length > 0) {
      return _(element.children).chain().each(function(child) {
        return crawl(fqn, child, callback);
      });
    }
  };
  return DomProxy;
})();
DivProxy = (function() {
  __extends(DivProxy, DomProxy);
  function DivProxy() {
    DivProxy.__super__.constructor.apply(this, arguments);
  }
  DivProxy.prototype.write = function(path, value) {
    var proxy;
    if (path === this.namespace) {
      if (_.isObject(value)) {
        return self.crawl("", value, function(namespace, key, child) {
          this.namespace = namespace;
          return self.write(buildFqn(this.namespace, key), child);
        });
      } else {
        return $(this.element).text(value);
      }
    } else {
      proxy = self[path];
      return proxy.write(path, value);
    }
  };
  return DivProxy;
})();
SpanProxy = (function() {
  __extends(SpanProxy, DomProxy);
  function SpanProxy() {
    SpanProxy.__super__.constructor.apply(this, arguments);
  }
  SpanProxy.prototype.write = function(path, value) {
    var proxy;
    if (path === this.namespace) {
      return $(this.element).text(value);
    } else {
      proxy = self[path];
      return proxy.write(path, value);
    }
  };
  return SpanProxy;
})();
InputProxy = (function() {
  __extends(InputProxy, DomProxy);
  function InputProxy() {
    InputProxy.__super__.constructor.apply(this, arguments);
  }
  InputProxy.prototype.write = function(path, value) {
    var proxy;
    if (path === this.namespace) {
      return $(this.element).val(value);
    } else {
      proxy = self[path];
      return proxy.write(path, value);
    }
  };
  return InputProxy;
})();
UlProxy = (function() {
  __extends(UlProxy, DomProxy);
  function UlProxy() {
    UlProxy.__super__.constructor.apply(this, arguments);
  }
  UlProxy.prototype.write = function(path, value) {
    var children, indx, li, proxy;
    if (path === this.namespace) {
      children = $(this.element).children("li");
      if (children.length < value.length) {
        li = children[0];
        indx = 0;
        return _(value).each(function(child) {
          var newLi;
          newLi = $(li).clone().attr("id", indx).appendTo(element);
          self[fqn + "." + indx] = newLi[0];
          return indx++;
        });
      }
    } else {
      proxy = self[path];
      return proxy.write(path, value);
    }
  };
  return UlProxy;
})();
LiProxy = (function() {
  __extends(LiProxy, DomProxy);
  function LiProxy() {
    LiProxy.__super__.constructor.apply(this, arguments);
  }
  LiProxy.prototype.write = function(path, value) {
    if (path === this.namespace) {
      return $(this.element).text(value);
    }
  };
  return LiProxy;
})();
domFactory = function(target, namespace) {
  var element;
  this["div"] = function(target, namespace) {
    return new DivProxy(target, namespace);
  };
  this["span"] = function(target, namespace) {
    return new SpanProxy(target, namespace);
  };
  this["input"] = function(target, namespace) {
    return new InputProxy(target, namespace);
  };
  this["ul"] = function(target, namespace) {
    return new UlProxy(target, namespace);
  };
  this["li"] = function(target, namespace) {
    return new LiProxy(target, namespace);
  };
  if (_.isString(target)) {
    element = $(target)[0];
    return this[element.tagName.toLowerCase()](element, namespace);
  } else {
    return this[target[0].tagName.toLowerCase()](target, namespace);
  }
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
  },
  scan: function(target, namespace) {
    return domFactory(target, namespace);
  }
};
context["replicant"] = replicant;
})(window);