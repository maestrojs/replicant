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
onProxyOf = function(value, ifArray, ifObject, absorb, otherwise) {
  var isArray, isFunction, isObject, isProxied;
  isObject = _(value).isObject();
  isArray = _(value).isArray();
  isFunction = _(value).isFunction();
  isProxied = value instanceof ObjectProxy || value instanceof ArrayProxy;
  if (isProxied) {
    return absorb();
  } else if (!isFunction && (isObject || isArray)) {
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
    return onGet(self, key, value);
  };
  setCallback = function(key, newValue, oldValue) {
    return onSet(self, key, newValue, oldValue);
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
        return _(value).chain().keys().each(function(k) {
          addChildPath("" + fqn + "." + k, value, k);
          return value;
        });
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
  return setCallback(fqn, self[subject.length - 1], void 0);
};
this.unshift = function(value) {
  var fqn, key;
  key = subject.length;
  subject.push(value);
  createIndex(proxy, key);
  fqn = buildFqn(path, key);
  return setCallback(fqn, self[0], self[1]);
};
this.pop = function() {
  var fqn, key, value;
  value = self[subject.length - 1];
  subject.pop();
  key = subject.length - 1;
  fqn = buildFqn(path, key);
  setCallback(fqn, void 0, value);
  delete self[subject.length];
  return value;
};
this.shift = function() {
  var fqn, value;
  value = self[0];
  subject.shift();
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
    onGet(self, key, value);
    return lastRead.push(key);
  };
  setCallback = function(key, newValue, oldValue) {
    onSet(self, key, newValue, oldValue);
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
        return _(value).chain().keys().each(function(k) {
          addChildPath("" + fqn + "." + k, value, k);
          return value;
        });
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
var Cartographer;
Cartographer = function(target, namespace) {
  var channel, conditionalCopy, copyProperties, crawl, createFqn, eventHandlers, makeTag, modelTargets, setupEvents, subscribe, templateProperties, wireup;
  this.element = $(target)[0];
  this.map = function() {};
  this.html = DOMBuilder.dom;
  this.template = {};
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
  this.fqn = createFqn(namespace, this.element["id"]);
  this.eventChannel = postal.channel(this.fqn + "_events");
  channel = this.eventChannel;
  subscribe = function(context) {
    return postal.channel(context.fqn + "_model").subscribe(function(m) {
      var addName, childKey, control, lastIndex, newElement, parentKey;
      if (m.event === "wrote") {
        control = context[m.key];
        lastIndex = m.key.lastIndexOf(".");
        parentKey = m.key.substring(0, lastIndex);
        childKey = m.key.substring(lastIndex + 1);
        if (childKey === "value" && !control) {
          control = context[parentKey];
        }
        if (control) {
          control.value = m.value;
          return control.textContent = m.value;
        } else {
          addName = parentKey + "_add";
          newElement = context.template[addName](childKey, m.parent);
          return $(context[parentKey]).append(newElement);
        }
      }
    });
  };
  subscribe(this);
  eventHandlers = {
    click: "onclick",
    dblclick: "ondblclick",
    mousedown: "onmousedown",
    mouseup: "onmouseup",
    mouseove: "onmouseover",
    mousemove: "onmousemove",
    mouseout: "onmouseout",
    keydown: "onkeydown",
    keypress: "onkeypress",
    keyup: "onkeyup",
    select: "onselect",
    change: "onchange",
    focus: "onfocus",
    blur: "onblur",
    scroll: "onscroll",
    resize: "onresize",
    submit: "onsubmit"
  };
  modelTargets = {
    hide: "hidden",
    value: ["value", "textContent"]
  };
  templateProperties = {
    id: "id",
    name: "name",
    "class": "className",
    type: "type"
  };
  crawl = function(context, root, namespace, element) {
    var call, child, createChildren, fqn, id, tag;
    id = element["id"];
    fqn = createFqn(namespace, id);
    tag = element.tagName.toUpperCase();
    context = context || root;
    if (element.children !== void 0 && element.children.length > 0) {
      createChildren = (function() {
        var _i, _len, _ref, _results;
        _ref = element.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          _results.push(crawl(context, root, fqn, child));
        }
        return _results;
      })();
      call = function(html, model, parentFqn, idx) {
        var actualId, call, childElement, childFactory, controls, indx, list, myFqn, val, _ref;
        actualId = id === "" ? idx : id;
        myFqn = createFqn(parentFqn, actualId);
        val = actualId === fqn || actualId === void 0 ? model : model[actualId];
        if (val instanceof ArrayProxy) {
          list = [];
          childFactory = createChildren[0];
          context.template[myFqn + "_add"] = function(newIndex, newModel) {
            return childFactory(html, newModel, myFqn, newIndex);
          };
          for (indx = 0, _ref = val.length - 1; 0 <= _ref ? indx <= _ref : indx >= _ref; 0 <= _ref ? indx++ : indx--) {
            list.push(childFactory(html, val, myFqn, indx));
          }
          childElement = makeTag(context, html, tag, element, myFqn, actualId, list, root, model);
          context[myFqn] = childElement;
          return childElement;
        } else {
          controls = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = createChildren.length; _i < _len; _i++) {
              call = createChildren[_i];
              _results.push(call(html, val, myFqn));
            }
            return _results;
          })();
          childElement = makeTag(context, html, tag, element, myFqn, actualId, controls, root, model);
          context[myFqn] = childElement;
          return childElement;
        }
      };
      context.template[fqn] = call;
      return call;
    } else {
      call = function(html, model, parentFqn, idx) {
        var actualId, childElement, myFqn, val;
        actualId = id === "" ? idx : id;
        myFqn = createFqn(parentFqn, actualId);
        val = actualId === fqn ? model : model[actualId];
        childElement = makeTag(context, html, tag, element, myFqn, actualId, val, root, model);
        context[myFqn] = childElement;
        return childElement;
      };
      context.template[fqn] = call;
      return call;
    }
  };
  makeTag = function(context, html, tag, template, myFqn, id, val, root, model) {
    var content, element, properties;
    properties = {};
    content = val ? val : template.textContent;
    if (id || id === 0) {
      properties.id = id;
    }
    if (tag === "INPUT") {
      properties.value = content;
    }
    if (template) {
      copyProperties(template, properties, templateProperties);
    }
    element = html[tag](properties, content);
    if (model[id]) {
      copyProperties(model[id], element, modelTargets);
    }
    setupEvents(model[id], root, myFqn, element, context);
    return element;
  };
  setupEvents = function(model, root, fqn, element, context) {
    var x, _i, _len, _ref, _results;
    if (model) {
      _ref = _.keys(eventHandlers);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        x = _ref[_i];
        _results.push(wireup(x, eventHandlers[x], model, root, fqn, element, context));
      }
      return _results;
    }
  };
  wireup = function(alias, event, model, root, fqn, element, context) {
    var handler;
    handler = model[alias];
    if (handler) {
      return element[event] = handler.bind(root);
    } else {
      return element[event] = function(x) {
        context.eventChannel.publish({
          control: fqn,
          event: event,
          context: context
        });
        return x.stopPropagation();
      };
    }
  };
  copyProperties = function(source, target, list) {
    var x, _i, _len, _ref, _results;
    _ref = _.keys(list);
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      x = _ref[_i];
      _results.push(conditionalCopy(source, target, x, list[x]));
    }
    return _results;
  };
  conditionalCopy = function(source, target, sourceId, targetId) {
    var val, x, _i, _len, _results;
    val = source[sourceId];
    if (val) {
      if (_.isArray(targetId)) {
        _results = [];
        for (_i = 0, _len = targetId.length; _i < _len; _i++) {
          x = targetId[_i];
          _results.push((target[x] = val));
        }
        return _results;
      } else {
        return target[targetId] = val;
      }
    }
  };
  this.map = function(model) {
    var fn;
    fn = crawl(this, model, namespace, this.element, this.map);
    return fn(this.html, model);
  };
  return this;
};
var replicant;
replicant = {
  "default": {
    onGet: function(parent, key, value) {
      return console.log("read: " + key + " -> " + value);
    },
    onSet: function(parent, key, value, old) {
      return console.log("wrote: " + key + ". " + old + " -> " + value);
    },
    namespace: ""
  },
  create: function(target, get, set, namespace) {
    var channel, onGet, onSet, proxy;
    channel = postal.channel(namespace + "_model");
    onGet = get || (get = function(parent, key, value) {
      return channel.publish({
        event: "read",
        parent: parent,
        key: key,
        value: value
      });
    });
    onSet = set || (set = function(parent, key, value, old) {
      return channel.publish({
        event: "wrote",
        parent: parent,
        key: key,
        value: value,
        original: old
      });
    });
    namespace = namespace || (namespace = this["default"].namespace);
    proxy = onProxyOf(target, function() {
      return new ArrayProxy(target, onGet, onSet, namespace);
    }, function() {
      return new ObjectProxy(target, onGet, onSet, namespace);
    }, function() {
      return target;
    });
    postal.channel(namespace + "_events").subscribe(function(m) {
      if (m.event === "onchange") {
        return proxy[m.control] = m.context[m.control].value;
      }
    });
    return proxy;
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