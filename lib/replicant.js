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
  isProxied = value instanceof ObjectWrapper || value instanceof ArrayWrapper;
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
var ArrayWrapper, ObjectWrapper, Proxy;
ObjectWrapper = function(target, onEvent, namespace, addChild, removeChild) {
  var proxy;
  proxy = new Proxy(this, target, onEvent, namespace, addChild, removeChild);
  this.change_path = function(p) {
    return proxy.change_path(p);
  };
  return this;
};
ArrayWrapper = function(target, onEvent, namespace, addChild, removeChild) {
  var proxy;
  proxy = new Proxy(this, target, onEvent, namespace, addChild, removeChild);
  this.change_path = function(p) {
    return proxy.change_path(p);
  };
  this.push = function(value) {
    return proxy.push(value);
  };
  this.unshift = function(value) {
    return proxy.unshift(value);
  };
  this.pop = function() {
    return proxy.pop;
  };
  this.shift = function() {
    return proxy.shift;
  };
  return this;
};
Proxy = function(wrapper, target, onEvent, namespace, addChild, removeChild) {
  var addChildPath, addToParent, ancestors, createMemberProxy, createProxyFor, notify, path, proxy, removeChildPath, removeFromParent, subject;
  proxy = {};
  path = namespace || (namespace = "");
  addToParent = addChild || function() {};
  removeFromParent = removeChild || function() {};
  subject = target;
  ancestors = [];
  this.change_path = function(p) {
    return path = p;
  };
  this.push = function(value) {
    var fqn, key, newIndex;
    key = subject.length;
    subject.push(value);
    createMemberProxy(key);
    fqn = buildFqn(path, key);
    newIndex = subject.length - 1;
    return notify(fqn, "added", {
      index: newIndex,
      value: wrapper[newIndex]
    });
  };
  this.unshift = function(value) {
    var fqn, key;
    key = subject.length;
    subject.push(value);
    createMemberProxy(key);
    fqn = buildFqn(path, key);
    return notify(fqn, "added", {
      index: 0,
      value: wrapper[0]
    });
  };
  this.pop = function() {
    var fqn, key, value;
    value = wrapper[subject.length - 1];
    subject.pop();
    key = subject.length - 1;
    fqn = buildFqn(path, key);
    delete wrapper[subject.length];
    notify(fqn, "removed", {
      index: subject.length,
      value: value
    });
    return value;
  };
  this.shift = function() {
    var fqn, value;
    value = wrapper[0];
    subject.shift();
    fqn = buildFqn(path, "0");
    delete wrapper[subject.length];
    notify(fqn, "removed", {
      index: 0,
      value: value
    });
    return value;
  };
  addChildPath = function(fqn, child, key) {
    Object.defineProperty(wrapper, fqn, {
      get: function() {
        return child[key];
      },
      set: function(value) {
        return child[key] = value;
      },
      configurable: true
    });
    if (child !== wrapper && !_.any(child.ancestors, function(x) {
      return x === wrapper;
    })) {
      child.ancestors.push(wrapper);
    }
    return addToParent(fqn, child, key);
  };
  removeChildPath = function(fqn) {
    delete wrapper[fqn];
    return removeFromParent(fqn);
  };
  notify = function(key, event, info) {
    return onEvent(wrapper, key, event, info);
  };
  createProxyFor = function(writing, fqn, key) {
    var value;
    value = subject[key];
    if (writing || proxy[key] === void 0) {
      proxy[key] = onProxyOf(value, function() {
        return new ArrayWrapper(value, onEvent, fqn, addChildPath, removeChildPath);
      }, function() {
        return new ObjectWrapper(value, onEvent, fqn, addChildPath, removeChildPath);
      }, function() {
        _(value).chain().keys().each(function(k) {
          addChildPath("" + fqn + "." + k, value, k);
          return value.change_path(fqn);
        });
        return value;
      }, function() {
        return value;
      });
    }
    return proxy[key];
  };
  createMemberProxy = function(key) {
    var fqn;
    fqn = buildFqn(path, key);
    addChildPath(fqn, wrapper, key);
    createProxyFor(false, fqn, key);
    return Object.defineProperty(wrapper, key, {
      get: function() {
        var fqn1, value;
        fqn1 = buildFqn(path, key);
        value = createProxyFor(false, fqn1, key);
        notify(fqn1, "read", {
          value: value
        });
        return value;
      },
      set: function(value) {
        var fqn1, newValue, old;
        fqn1 = buildFqn(path, key);
        old = proxy[key];
        subject[key] = value;
        newValue = createProxyFor(true, fqn1, key);
        return notify(fqn1, "wrote", {
          value: value,
          previous: old
        });
      },
      configurable: true,
      enumerable: true
    });
  };
  Object.defineProperty(wrapper, "length", {
    get: function() {
      return subject.length;
    }
  });
  Object.defineProperty(wrapper, "ancestors", {
    get: function() {
      return ancestors;
    },
    set: function(x) {
      return ancestors = x;
    },
    enumerable: false,
    configurable: true
  });
  _(target).chain().keys().each(function(key) {
    return createMemberProxy(key);
  });
  return this;
};
var Cartographer;
Cartographer = function(target, namespace) {
  var channel, conditionalCopy, copyProperties, crawl, createFqn, eventHandlers, makeTag, modelTargets, modelTargetsForCollections, setupEvents, subscribe, templateProperties, wireup;
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
      if (m.event !== "read") {
        control = context[m.key];
        lastIndex = m.key.lastIndexOf(".");
        parentKey = m.key.substring(0, lastIndex);
        childKey = m.key.substring(lastIndex + 1);
        target = "value";
        if (childKey === "value" || !control) {
          control = context[parentKey];
          target = childKey;
        }
        if (m.event === "wrote") {
          if (control) {
            return conditionalCopy(m.info, control, "value", modelTargets[target]);
          }
        } else if (m.event === "added") {
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
    mouseover: "onmouseover",
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
    title: "title",
    "class": "className",
    value: ["value", "textContent"]
  };
  modelTargetsForCollections = {
    hide: "hidden",
    title: "title",
    value: "value",
    "class": "className"
  };
  templateProperties = {
    id: "id",
    name: "name",
    title: "title",
    className: "class",
    type: "type",
    width: "width",
    height: "height"
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
        var actualId, call, childElement, childFactory, collection, controls, indx, list, myFqn, val, _ref;
        actualId = id === "" ? idx : id;
        myFqn = createFqn(parentFqn, actualId);
        val = actualId === fqn || actualId === void 0 ? model : model != null ? model[actualId] : void 0;
        collection = val instanceof ArrayWrapper ? val : val != null ? val.items : void 0;
        if (collection && collection instanceof ArrayWrapper) {
          list = [];
          childFactory = createChildren[0];
          context.template[myFqn + "_add"] = function(newIndex, newModel) {
            return childFactory(html, newModel, myFqn, newIndex);
          };
          for (indx = 0, _ref = collection.length - 1; 0 <= _ref ? indx <= _ref : indx >= _ref; 0 <= _ref ? indx++ : indx--) {
            list.push((function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = createChildren.length; _i < _len; _i++) {
                call = createChildren[_i];
                _results.push(call(html, collection, myFqn, indx));
              }
              return _results;
            })());
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
        val = actualId === fqn ? model : model != null ? model[actualId] : void 0;
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
    element = {};
    if (id || id === 0) {
      properties.id = id;
    }
    if (template) {
      copyProperties(template, properties, templateProperties);
    }
    if (tag === "INPUT") {
      if (!_.isObject(content)) {
        properties.value = content;
      }
      element = html[tag](properties);
    } else {
      element = html[tag](properties, content);
    }
    if (model != null ? model[id] : void 0) {
      if (val instanceof Array) {
        copyProperties(model[id], element, modelTargetsForCollections);
      } else {
        copyProperties(model[id], element, modelTargets);
      }
    }
    setupEvents(model != null ? model[id] : void 0, root, myFqn, element, context);
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
    var handler, handlerProxy;
    handler = model[alias];
    if (handler) {
      handlerProxy = function(x) {
        return handler.apply(model, [
          root, {
            id: fqn,
            control: context[fqn],
            event: event,
            context: context,
            info: x
          }
        ]);
      };
      return element[event] = handlerProxy;
    } else {
      return element[event] = function(x) {
        if (event === "onchange") {
          x.stopPropagation();
        }
        return context.eventChannel.publish({
          id: fqn,
          model: model,
          control: context[fqn],
          event: event,
          context: context,
          info: x
        });
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
    if (val !== void 0 && (val !== "" && targetId !== "value")) {
      if (_.isArray(targetId)) {
        _results = [];
        for (_i = 0, _len = targetId.length; _i < _len; _i++) {
          x = targetId[_i];
          _results.push((target[x] = val));
        }
        return _results;
      } else {
        target[targetId] = val;
        return console.log("Writing " + val + " to " + targetId + " of " + target);
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
  create: function(target, onevent, namespace) {
    var channel, onEvent, proxy;
    channel = postal.channel(namespace + "_model");
    onEvent = onevent || (onevent = function(parent, key, event, info) {
      return channel.publish({
        event: event,
        parent: parent,
        key: key,
        info: info
      });
    });
    namespace = namespace || (namespace = "");
    proxy = onProxyOf(target, function() {
      return new ArrayWrapper(target, onEvent, namespace);
    }, function() {
      return new ObjectWrapper(target, onEvent, namespace);
    }, function() {
      return target;
    });
    (function() {
      return target;
    });
    postal.channel(namespace + "_events").subscribe(function(m) {
      if (m.event === "onchange") {
        return proxy[m.id] = m.control.value;
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