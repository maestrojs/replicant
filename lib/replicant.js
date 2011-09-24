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
  path = namespace || (namespace = "");
  noOp = function() {};
  addToParent = addChild;
  removeFromParent = removeChild;
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
    if (addToParent) {
      return addToParent(fqn, child, key);
    }
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
    if (addToParent) {
      addToParent(fqn, self, key);
    } else {
      addChildPath(fqn, self, key);
    }
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
      return proxy.length;
    }
  });
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
    this.element = target;
    this.fqn = namespace === "" || namespace === void 0 ? this.element["id"] : buildFqn(namespace, this.element["id"]);
    this.crawl(this, this.fqn, this.element, this.crawl, this.addChild);
    this;
  }
  DomProxy.prototype.addChild = function(context, namespace, key, child) {
    var member;
    member = buildFqn(namespace, key);
    return context[member] = domFactory(child, namespace);
  };
  DomProxy.prototype.crawl = function(context, namespace, element, crawl, callback) {
    if (element.children !== void 0 && element.children.length > 0) {
      return _(element.children).chain().each(function(child) {
        callback(context, namespace, child["id"], child);
        return crawl(context, namespace, child, crawl, callback);
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
    var proxy, x, _i, _len, _results;
    if (path === this.fqn) {
      if (_.isObject(value)) {
        _results = [];
        for (_i = 0, _len = value.length; _i < _len; _i++) {
          x = value[_i];
          _results.push(this[x].write(value[x]));
        }
        return _results;
      } else {
        return $(this.element).text(value);
      }
    } else {
      proxy = this[path];
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
    if (path === this.fqn) {
      return $(this.element).text(value);
    } else {
      proxy = this[path];
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
    if (path === this.fqn) {
      return $(this.element).val(value);
    } else {
      proxy = this[path];
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
    if (path === this.fqn) {
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
      proxy = this[path];
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
    if (path === this.fqn) {
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
    return this[target.tagName.toLowerCase()](target, namespace);
  }
};
var Cartographer;
Cartographer = function(target, namespace) {
  var crawl, createFqn, makeTag;
  this.element = $(target)[0];
  this.map = function() {};
  this.fqn = namespace === "" || namespace === void 0 ? this.element["id"] : buildFqn(namespace, this.element["id"]);
  this.html = DOMBuilder.html;
  createFqn = function(namespace, id) {
    var result;
    if (id === void 0 || id === "") {
      result = namespace;
    } else if (namespace === void 0 || namespace === "") {
      result = id;
    } else {
      result = "" + namespace + "." + id;
    }
    return result;
  };
  crawl = function(context, namespace, element) {
    var child, createChildren, fqn, id, tag;
    id = element["id"];
    fqn = createFqn(namespace, id);
    tag = element.tagName.toUpperCase();
    if (element.children !== void 0 && element.children.length > 0) {
      createChildren = (function() {
        var _i, _len, _ref, _results;
        _ref = element.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(crawl(context, fqn, child));
        }
        return _results;
      })();
      return function(html, model, idx) {
        var actual, call, controls, indx, list, val, _ref;
        actual = id === "" ? idx : id;
        val = actual === fqn ? model : model[actual];
        if (val instanceof ArrayProxy) {
          list = [];
          for (indx = 0, _ref = val.length - 1; 0 <= _ref ? indx <= _ref : indx >= _ref; 0 <= _ref ? indx++ : indx--) {
            list.push((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = createChildren.length; _i < _len; _i++) {
                call = createChildren[_i];
                _results.push(call(html, val, indx));
              }
              return _results;
            })());
          }
          return makeTag(html, tag, actual, element, list);
        } else {
          controls = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = createChildren.length; _i < _len; _i++) {
              call = createChildren[_i];
              _results.push(call(html, val));
            }
            return _results;
          })();
          return makeTag(html, tag, actual, element, controls);
        }
      };
    } else {
      return function(html, model, idx) {
        var actual, indx, list, val, x, _ref;
        actual = id === "" ? idx : id;
        val = actual === fqn ? model : model[actual];
        x = 0;
        if (val === void 0) {
          if (actual === "" || actual === void 0) {
            return makeTag(html, tag, "", element, element.textContent);
          } else {
            return html[tag]();
          }
        } else if (val instanceof ArrayProxy) {
          list = [];
          for (indx = 0, _ref = val.length - 1; 0 <= _ref ? indx <= _ref : indx >= _ref; 0 <= _ref ? indx++ : indx--) {
            list.push(makeTag(html, tag, indx, element, val[indx]));
          }
          return list;
        } else {
          return makeTag(html, tag, actual, element, val);
        }
      };
    }
  };
  makeTag = function(html, tag, id, template, val) {
    var properties;
    properties = {
      id: id
    };
    if (template.className) {
      properties["class"] = template.className;
    }
    if (val.onclick) {
      properties.onclick = val.onclick;
    }
    if (val.onblur) {
      properties.onblur = val.onblur;
    }
    return html[tag](properties, val);
  };
  this.map = function(model) {
    var fn;
    fn = crawl(this, namespace, this.element, this.map);
    return fn(this.html, model);
  };
  return this;
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
  },
  map: function(target) {
    return new Cartographer(target, "");
  }
};
context["replicant"] = replicant;
})(window);