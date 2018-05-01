
var schweb = new function() {
  var myself = this
  var base_url = "/" //https://localhost:4443/"
  var req = new XMLHttpRequest()
  req.withCredentials = true

  this.run = function() {
    window.addEventListener('hashchange', renderUrl)
    Handlebars.registerPartial('list-menu', document.getElementById("tmpl-list-menu").innerHTML)
    Handlebars.registerPartial('page-header', document.getElementById("tmpl-page-header").innerHTML)
    renderUrl()
  }

  var hideAllPages = function() {
      document.querySelectorAll(".page").forEach(function(element) {
        element.classList.remove("visible")
      })
  }

  var renderUrl = function() {
    console.log("renderUrl")
    var hash = decodeURI(window.location.hash);
    var [thing, id] = hash.replace('#', '').split('/')
    hideAllPages()
    try {
      myself["show" + thing](id)
    } catch {
      console.error("No handler found for this URL! thing: ", thing, "id: ", id)
    }
  }

  var xhrSuccessHandler = function(callback) {
    if (req.readyState === XMLHttpRequest.DONE) {
      if (req.status === 200) {
        data = JSON.parse(req.responseText)
        console.log('calling callback');
        callback(data);
      } else {
        console.error('There was a problem with the request: ', req);
      }
    }
  }

  var appendParamsToUrl = function(url, params) {
    if (params) {
      url += "?"
      Object.keys(params).map(function(key) {
        url += key + "=" + params[key]
      })
    }
    return url
  }

  var buildUrl = function(path, params) {
    return appendParamsToUrl(base_url + path + ".json", params)
  }

  this.get = function(path, params, callback) {
    req.open("GET", buildUrl(path, params))
    //req.setRequestHeader("Authorization", "Basic " + btoa("schleuder:445afc876b3f36877704c6b0c77942c79ef7998c45f1650fa8a2a66b82266fff"));
    req.onreadystatechange = function() { xhrSuccessHandler(callback) }
    console.log("Fetching data")
    req.send()
  }

  this.show = function() {
    console.log("rendering homepage")
    myself.get('lists', null, function(data) {
      renderHtml('lists', {lists: data})
    })
  }

  this.showlists = function(id) {
    myself.get('lists/' + id, null, function(data) {
      renderHtml('list-options', {list: data})
    })
  }

  this.showsubscriptions = function(id) {
    var context = {}
    myself.get('lists/' + id, null, function(data) {
      context["list"] = data
      myself.get('subscriptions', {list_id: id}, function(data) {
        context["subscriptions"] = data
        renderHtml('list-subscriptions', context)
      })
    })
  }

  this.showkeys = function(ids) {
    var [list_id, fingerprint] = ids.split('|')
    var context = {}
    myself.get('lists/' + list_id, null, function(data) {
      context["list"] = data
      if (fingerprint) {
        myself.get('keys/' + fingerprint, {list_id: list_id}, function(data) {
          context["key"] = data
          renderHtml('key', context)
        })
      } else {
        myself.get('keys', {list_id: list_id}, function(data) {
          context["keys"] = data
          renderHtml('keys', context)
        })
      }
    })
  }

  var removeElements = function() {
    document.body.querySelectorAll(".page").forEach(function(element) {
      element.parentNode.removeChild(element)
    })
  }

  var renderHtml = function(name, context) {
    var source   = document.getElementById("tmpl-" + name).innerHTML
    var template = Handlebars.compile(source)
    var container = document.querySelector("div." + name)
    var oldPage = container.querySelector(".page")
    if (oldPage) {
      container.removeChild(oldPage)
    }
    var html = template(context)
    container.insertAdjacentHTML('beforeend', html)
  }

}

window.addEventListener("load", function() { schweb.run() })

