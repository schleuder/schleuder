import "./html-element.js"
import LoginForm from './components/login-form.js'
import ListIndex from './components/list-index.js'
import ListForm from './components/list-form.js'
import ListMenu from './components/list-menu.js'
import SubscriptionIndex from './components/subscription-index.js'
import SubscriptionShow from './components/subscription-show.js'
import SubscriptionForm from './components/subscription-form.js'
import KeyIndex from './components/key-index.js'
import KeyShow from './components/key-show.js'
import KeyForm from './components/key-form.js'
import NotiFier from './noti-fier.js'
import Backend from './backend.js'
import UserMenu from './user-menu.js'
import State from './state.js'
import {div, ul, li, a} from './hyper.js'
import {t} from "./translations.js"

export default class Router {
  static start() {
    this.loadingIcon = document.querySelector('.loading-icon')
    this.loadingIcon.hide()
    this.elemCache = new Map()
    // TODO: Check on load if we have valid credentials.
    // TODO: Maybe use session ticket from API (after implementing it in API...)
    window.addEventListener('popstate', (event) => { console.debug(event); this.route() })
    this.route()
  }

  static async route(urlPath, msg, msgKlass='notice') {
    try {
      this.loadingIcon.show()
      if (urlPath) {
        console.debug(`pushing '#${urlPath}' to history`)
        history.pushState({}, urlPath, `#${urlPath}`)
      } else {
        urlPath = window.location.hash
      }
      if (urlPath[0] === '#') {
        urlPath = urlPath.slice(1)
      }

      if (msg) {
        NotiFier.show(msgKlass, msg)
      } else {
        NotiFier.clearAll()
      }

      // Don't allow the user to see cached data unless they are authenticated.
      if (urlPath !== 'login') {
        if (! Backend.hasCredentials()) {
          return this.route('login')
        }
      }
      
      let cacheHit = false
      for (let [path, elem] of this.elemCache) {
        if (path === urlPath) {
          elem.show()
          cacheHit = true
        } else {
          elem.hide()
        }
      }
      if (cacheHit) {
        this.loadingIcon.hide()
        return
      }

      const thing = await this.callRenderer(urlPath)
      if (thing instanceof HTMLElement) {
        document.body.append(thing)
        this.elemCache.set(urlPath, thing)
      }
    } catch (exc) {
      console.error(exc)
      if (exc instanceof TypeError && exc.message.slice(0, 12) === 'NetworkError') {
        NotiFier.error(t("error_could_not_connect_to_server"))
      } else {
        NotiFier.error(t("error_unexpected_problem"))
      }
      this.loadingIcon.hide()
    }
  }

  // TODO: set page title
  static callRenderer(urlPath) {
    // Split URL into parts and filter out empty segments.
    const [mainAction, listname, listAction, thingId, thingAction, ...rest] = urlPath.split('/').filter((part) => part)

    // Check this early to enable running other code for all other paths.
    switch(mainAction) {
      case 'login':
        Backend.clearCredentials()
        this.loadingIcon.hide()
        return new LoginForm()
      case 'logout':
        Backend.clearCredentials()
        this.userMenu.remove()
        this.userMenu = undefined
        this.elemCache.forEach((view) => view.remove())
        this.elemCache.clear()
        return this.route('login', 'You have been logged out!')
    }

    // Any other URL that doesn't start with 'lists' is unknown.
    if (mainAction !== 'lists') {
      return this.route('lists')
    }

    if (! this.userMenu) {
      this.userMenu = new UserMenu(State.get('emailaddr'))
      document.querySelector('#header').append(this.userMenu);
    }

    const view = div({class: 'view'})

    if (! listname) {
      view.append(new ListIndex())
      return view;
    }

    view.append(new ListMenu(listname, urlPath))

    console.debug({listAction});
    let elem
    switch (listAction) {
      case 'edit':
        elem = new ListForm(listname)
        break;
      case undefined:
        elem = new SubscriptionIndex(listname)
        break;
      case 'subscriptions':
        switch(thingId) {
          case undefined:
            elem = new SubscriptionIndex(listname)
            break
          case 'new':
            elem = new SubscriptionForm(listname)
            break
          default:
            if (thingAction === 'edit') {
              elem = new SubscriptionForm(listname, thingId)
            } else {
              elem = new SubscriptionShow(listname, thingId);
            }
        }
        break;
      case 'keys':
        switch(thingId) {
          case undefined:
            elem = new KeyIndex(listname)
            break
          case 'new':
            elem = new KeyForm(listname)
            break
          default:
            if (thingAction === 'edit') {
              elem = new KeyForm(listname, thingId)
            } else {
              elem = new KeyShow(listname, thingId);
            }
            break;
        }
        break;
      default:
        return this.route("#lists", t("error_unexpected_problem"), "error");
    }
    view.append(elem)

    return view
  }

  //static listMenuItems = {subscriptions: "Subscriptions", keys: "Keys", edit: "List options"}
  //
  //static listMenu(listname, currentUrl) {
  //  const elem = div({class: 'list-menu'})
  //  const headline = div({class: "pageheadline"})
  //  elem.append(headline);
  //  if (! listname) {
  //    headline.textContent = "My lists"
  //  } else {
  //    headline.textContent = listname
  //    const menuElems = Object.keys(this.listMenuItems).map((urlPart) => {
  //      const text = this.listMenuItems[urlPart]
  //      const url = `lists/${listname}/${urlPart}`
  //      if (url === currentUrl) {
  //        return li(text)
  //      } else {
  //        return li(a({href: `#${url}`}, text))
  //      }
  //    })
  //    elem.append(ul(menuElems))
  //  }
  //  return elem;
  //}
}

