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
  var isArray, isFunction, isObject;
  isObject = _(value).isObject();
  isArray = _(value).isArray();
  isFunction = _(value).isFunction();
  if (!isFunction && (isObject || isArray)) {
    if (isArray) {
      return ifArray();
    } else {
      return ifObject();
    }
  } else {
    return otherwise();
  }
};
var Dependency, DependencyManager, dependencyManager;
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
DependencyManager = function() {
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
dependencyManager = new DependencyManager();
var ArrayWrapper, ObjectWrapper, Proxy;
ObjectWrapper = function(target, onEvent, namespace, addChild, removeChild) {
  var proxy;
  proxy = new Proxy(this, target, onEvent, namespace, addChild, removeChild);
  this.change_path = function(p) {
    return proxy.change_path(p);
  };
  this.addDependencyProperty = function(key, observable) {
    return proxy.addDependencyProperty(key, observable);
  };
  this.extractAs = function(alias) {
    return replicant.create(proxy.original, null, alias);
  };
  this.getOriginal = function() {
    return proxy.original;
  };
  this.subscribe = function(channelName) {
    return proxy.subscribe(channelName);
  };
  return this;
};
ArrayWrapper = function(target, onEvent, namespace, addChild, removeChild) {
  var proxy;
  proxy = new Proxy(this, target, onEvent, namespace, addChild, removeChild);
  this.change_path = function(p) {
    return proxy.change_path(p);
  };
  this.addDependencyProperty = function(key, observable) {
    return proxy.addDependencyProperty(key, observable);
  };
  this.extractAs = function(alias) {
    return replicant.create(proxy.original, null, alias);
  };
  this.getOriginal = function() {
    return proxy.original;
  };
  this.pop = function() {
    return proxy.pop();
  };
  this.push = function(value) {
    return proxy.push(value);
  };
  this.shift = function() {
    return proxy.shift();
  };
  this.subscribe = function(channelName) {
    return proxy.subscribe(channelName);
  };
  this.unshift = function(value) {
    return proxy.unshift(value);
  };
  return this;
};
Proxy = function(wrapper, target, onEvent, namespace, addChild, removeChild) {
  var addChildPath, addToParent, ancestors, createMemberProxy, createProxyFor, fullPath, getLocalFqn, getLocalPath, notify, path, proxy, readHook, removeChildPath, removeFromParent, self, subject, subscription, walk;
  self = this;
  fullPath = namespace || (namespace = "");
  addToParent = addChild || function() {};
  getLocalPath = function() {
    var parts;
    parts = fullPath.split('.');
    if (parts.length > 0) {
      return parts[parts.length - 1];
    } else {
      return fullPath;
    }
  };
  proxy = {};
  path = getLocalPath();
  removeFromParent = removeChild || function() {};
  subject = target;
  ancestors = [];
  readHook = null;
  subscription = {};
  addChildPath = function(lqn, child, key) {
    var fqn, isRoot, propertyName;
    isRoot = ancestors.length === 0;
    fqn = buildFqn(path, lqn);
    propertyName = isRoot ? fqn : lqn;
    Object.defineProperty(wrapper, propertyName, {
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
  this.subscribe = function(channelName) {
    if (subscription && subscription.unsubscribe) {
      subscription.unsubscribe();
    }
    return subscription = postal.channel(channelName).subscribe(function(m) {
      if (m.event === "onchange") {
        return wrapper[m.id] = m.control.value;
      }
    });
  };
  this.getHandler = function() {
    return onEvent;
  };
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
    value = value.getOriginal ? value.getOriginal() : value;
    if (writing || proxy[key] === void 0) {
      proxy[key] = onProxyOf(value, function() {
        return new ArrayWrapper(value, onEvent, fqn, addChildPath, removeChildPath);
      }, function() {
        return new ObjectWrapper(value, onEvent, fqn, addChildPath, removeChildPath);
      }, function() {
        return value;
      });
    }
    return proxy[key];
  };
  createMemberProxy = function(key) {
    var fqn, isRoot;
    fqn = buildFqn(path, key);
    createProxyFor(true, buildFqn(fullPath, key), key);
    Object.defineProperty(wrapper, key, {
      get: function() {
        var fqn1, value;
        fqn1 = buildFqn(fullPath, key);
        value = createProxyFor(false, fqn1, key);
        notify(fqn1, "read", {
          value: value
        });
        dependencyManager.recordAccess(wrapper, fqn1);
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
    isRoot = ancestors.length === 0;
    if (isRoot && fullPath !== "") {
      return addChildPath(key, wrapper, key);
    } else {
      return addToParent(fqn, wrapper, key);
    }
  };
  Object.defineProperty(wrapper, "length", {
    get: function() {
      var fqn1;
      fqn1 = buildFqn(fullPath, "length");
      notify(fqn1, "read", {
        value: subject.length
      });
      dependencyManager.recordAccess(wrapper, fqn1);
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
  this.addDependencyProperty = function(key, observable) {
    var fqn1, isRoot;
    fqn1 = buildFqn(fullPath, key);
    dependencyManager.watchFor(fqn1);
    observable(wrapper);
    dependencyManager.endWatch();
    Object.defineProperty(wrapper, key, {
      get: function() {
        return observable(wrapper);
      }
    });
    isRoot = ancestors.length === 0;
    if (isRoot && fullPath !== "") {
      return addChildPath(key, wrapper, key);
    } else {
      return addToParent(buildFqn(path, key), wrapper, key);
    }
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
        return self.addDependencyProperty(key, dependencyList[key]);
      });
    }
  };
  walk(target);
  addToParent(buildFqn(path, "length"), wrapper, "length");
  return this;
};
var Cartographer, Template;
Cartographer = function() {
  var self;
  self = this;
  postal.channel("cartographer").subscribe(function(m) {
    if (m.map) {
      return self.map(m.target, m.namespace);
    } else if (m.apply) {
      return self.apply(m.template, m.proxy, m.render, m.error);
    }
  });
  this.templates = {};
  this.map = function(target, namespace) {
    var template;
    template = new Template(target, namespace);
    return this.templates[template.fqn] = template;
  };
  this.apply = function(template, proxy, render, error) {
    var result, templateInstance;
    templateInstance = this.templates[template];
    if (templateInstance) {
      result = templateInstance.apply(proxy);
      if (render) {
        return render(result, templateInstance.fqn);
      } else {
        return $("#" + templateInstance.fqn).replaceWith(result);
      }
    } else if (error) {
      return error();
    }
  };
  return self;
};
context["cartographer"] = new Cartographer();
Template = function(target, namespace) {
  var conditionalCopy, copyProperties, crawl, createFqn, eventHandlers, makeTag, modelTargets, modelTargetsForCollections, self, setupEvents, subscribe, templateProperties, wireup;
  self = this;
  this.element = $(target)[0];
  this.apply = function() {};
  this.html = DOMBuilder.dom;
  this.template = {};
  this.changesSubscription;
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
  subscribe = function(context, channelName) {
    if (this.changeSubscription && this.changeSubscription.unsubscribe) {
      this.changeSubscription.ubsubscribe();
    }
    return this.changesSubscription = postal.channel(channelName).subscribe(function(m) {
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
  subscribe(self, self.fqn + "_model");
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
    if (val !== void 0) {
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
  this.apply = function(model) {
    var fn;
    fn = crawl(this, model, namespace, this.element, this.apply);
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
    dependencyManager.addNamespace(namespace);
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
    proxy.subscribe(namespace + "_events");
    return proxy;
  }
};
context["replicant"] = replicant;
})(window);