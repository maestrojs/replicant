(function(context) {
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
})(window);