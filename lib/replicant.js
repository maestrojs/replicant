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
var ArrayWrapper, Dependency, DependencyListener, ObjectWrapper, Proxy, dependencyListener;
Dependency = function(context, key, dependencies) {
  var self;
  self = this;
  _(dependencies).chain().each(function(x) {
    return self[x] = true;
  });
  this.add = function(dependency) {
    return self[dependency] = true;
  };
  this.isHit = function(fqn) {
    return self[fqn];
  };
  this.key = key;
  this.target = context;
  return self;
};
DependencyListener = function() {
  var addDependency, checkDependencies, dependencies, notify, self, watchingFor;
  dependencies = [];
  watchingFor = null;
  self = this;
  addDependency = function(context, fqn, key) {
    var dependency;
    dependency = _.detect(dependencies, function(x) {
      return x.key === fqn;
    });
    if (dependency) {
      return dependency.add(key);
    } else {
      dependency = new Dependency(context, fqn, [key]);
      return dependencies.push(dependency);
    }
  };
  checkDependencies = function(channelName, key) {
    return _(dependencies).chain().select(function(x) {
      return x.isHit(key);
    }).each(function(x) {
      return self[channelName].publish({
        event: "wrote",
        parent: x.target,
        key: x.key,
        info: {
          value: x.target[x.key],
          previous: null
        }
      });
    });
  };
  notify = function(key, event, info) {
    return onEvent(wrapper, key, event, info);
  };
  this.watchFor = function(fqn) {
    return watchingFor = fqn;
  };
  this.endWatch = function() {
    return watchingFor = null;
  };
  this.recordAccess = function(proxy, key) {
    if (watchingFor) {
      return addDependency(proxy, watchingFor, key);
    }
  };
  this.addNamespace = function(namespace) {
    var channelName;
    channelName = namespace + "_model";
    self[channelName] = postal.channel(channelName);
    return self[channelName].subscribe(function(m) {
      if (m.event === "wrote" || m.event === "added" || m.event === "removed") {
        return checkDependencies(channelName, m.key);
      }
    });
  };
  return self;
};
dependencyListener = new DependencyListener();
ObjectWrapper = function(target, onEvent, namespace, addChild, removeChild) {
  var proxy;
  proxy = new Proxy(this, target, onEvent, namespace, addChild, removeChild);
  this.change_path = function(p) {
    return proxy.change_path(p);
  };
  this.defineObservable = function(key, observable) {
    return proxy.defineObservable(key, observable);
  };
  this.extractAs = function(namespace) {
    return replicant.create(proxy.original, proxy.eventHandler, namespace);
  };
  this.getOriginal = function() {
    return proxy.original;
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
    return proxy.pop();
  };
  this.shift = function() {
    return proxy.shift();
  };
  this.defineObservable = function(key, observable) {
    return proxy.defineObservable(key, observable);
  };
  this.extractAs = function(namespace) {
    return replicant.create(proxy.original, proxy.eventHandler, namespace);
  };
  this.getOriginal = function() {
    return proxy.original;
  };
  return this;
};
Proxy = function(wrapper, target, onEvent, namespace, addChild, removeChild) {
  var addChildPath, addToParent, ancestors, createMemberProxy, createProxyFor, fullPath, getLocalFqn, getLocalPath, notify, path, proxy, readHook, removeChildPath, removeFromParent, self, subject, walk;
  self = this;
  fullPath = namespace || (namespace = "");
  addToParent = null;
  addChildPath = function(lqn, child, key) {
    var fqn, head, isRoot;
    isRoot = ancestors.length === 0;
    head = isRoot ? fullPath : path;
    fqn = buildFqn(head, lqn);
    lqn = isRoot ? fqn : lqn;
    Object.defineProperty(wrapper, lqn, {
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
    if (!isRoot) {
      return addToParent(fqn, child, lqn);
    }
  };
  addToParent = addChild || addChildPath;
  getLocalPath = function() {
    var parts;
    parts = fullPath.split('.');
    if (parts.length > 0) {
      return parts[parts.length - 1];
    } else {
      return "";
    }
  };
  proxy = {};
  path = getLocalPath();
  removeFromParent = removeChild || function() {};
  subject = target;
  ancestors = [];
  readHook = null;
  this.eventHandler = onEvent;
  this.change_path = function(p) {
    return fullPath = p;
  };
  this.add = function(key, keys) {
    var k, _i, _len;
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      k = keys[_i];
      createMemberProxy(k);
    }
    notify(buildFqn(fullPath, "length"), "wrote", {
      value: subject.length,
      previous: -1 + subject.length
    });
    return notify(buildFqn(fullPath, key), "added", {
      index: key,
      value: wrapper[key]
    });
  };
  this.push = function(value) {
    var key;
    key = -1 + subject.push(value);
    return this.add(key, [key]);
  };
  this.unshift = function(value) {
    var _i, _ref, _results;
    subject.unshift(value);
    return this.add(0, (function() {
      _results = [];
      for (var _i = 0, _ref = subject.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this));
  };
  this.remove = function(key, value, keys) {
    var k, _i, _len;
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      k = keys[_i];
      createMemberProxy(k);
    }
    notify(buildFqn(fullPath, "length"), "wrote", {
      value: subject.length,
      previous: 1 + subject.length
    });
    notify(buildFqn(fullPath, key), "removed", {
      index: subject.length,
      value: value
    });
    console.log(wrapper);
    return value;
  };
  this.original = subject;
  this.pop = function() {
    var key, value;
    key = subject.length - 1;
    value = wrapper[key];
    subject.pop();
    removeChildPath(key);
    return this.remove(key, value, []);
  };
  this.shift = function() {
    var key, value, _i, _ref, _results;
    key = 0;
    value = wrapper[key];
    subject.shift();
    removeChildPath(key);
    return this.remove(key, value, (function() {
      _results = [];
      for (var _i = 0, _ref = subject.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--){ _results.push(_i); }
      return _results;
    }).apply(this));
  };
  getLocalFqn = function(fqn) {
    var base, parts, result;
    parts = fqn.split(".");
    base = subject.constructor.name;
    return result = (function() {
      switch (parts.length) {
        case 0:
          return base;
        default:
          return "" + base + "." + parts[parts.length - 1];
      }
    })();
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
          addToParent(buildFqn(path, k), value, k);
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
    addToParent(fqn, wrapper, key);
    createProxyFor(true, buildFqn(fullPath, key), key);
    return Object.defineProperty(wrapper, key, {
      get: function() {
        var fqn1, value;
        fqn1 = buildFqn(fullPath, key);
        value = createProxyFor(false, fqn1, key);
        notify(fqn1, "read", {
          value: value
        });
        dependencyListener.recordAccess(wrapper, fqn);
        return value;
      },
      set: function(value) {
        var fqn1, newValue, old;
        fqn1 = buildFqn(fullPath, key);
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
      var fqn1;
      fqn1 = buildFqn(fullPath, "length");
      notify(fqn1, "read", {
        value: subject.length
      });
      dependencyListener.recordAccess(wrapper, fqn1);
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
  this.defineObservable = function(key, observable) {
    var fqn1;
    fqn1 = buildFqn(fullPath, key);
    dependencyListener.watchFor(fqn1);
    observable(wrapper);
    dependencyListener.endWatch();
    addToParent(buildFqn(path, key), wrapper, key);
    return Object.defineProperty(wrapper, key, {
      get: function() {
        return observable(wrapper);
      }
    });
  };
  walk = function(target) {
    var dependencyList;
    _(target).chain().keys().select(function(x) {
      return x !== "__dependencies__";
    }).each(function(key) {
      return createMemberProxy(key);
    });
    dependencyList = target.__dependencies__;
    if (dependencyList) {
      return _(dependencyList).chain().keys().each(function(key) {
        return self.defineObservable(key, dependencyList[key]);
      });
    }
  };
  walk(target);
  addToParent(buildFqn(path, "length"), wrapper, "length");
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
    height: "height",
    value: "value"
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
    var content, element, properties, templateSource;
    properties = {};
    templateSource = template.textContent ? template.textContent : template.value;
    content = val ? val : templateSource;
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
    if (val !== void 0 && (val !== "")) {
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
var TemplateLibrary;
TemplateLibrary = function(root) {
  var rootPath;
  rootPath = root;
  amplify.request.define("templateLoader", "ajax", {
    url: "{root}/{template}",
    dataType: "",
    type: "GET"
  });
  return this.getTemplate = function(name, onLoad) {
    return amplify.request("templateLoader", {
      template: name,
      root: rootPath
    }, function(data) {
      return onLoad(data);
    });
  };
};
var replicant;
replicant = {
  create: function(target, onevent, namespace) {
    var channel, onEvent, proxy;
    dependencyListener.addNamespace(namespace);
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