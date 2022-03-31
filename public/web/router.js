import LoginController from './login-controller.js';
import ListsController from './lists-controller.js';
import KeysController from './keys-controller.js';
import SubscriptionsController from './subscriptions-controller.js';
import Notifier from './notifier.js';
import Backend from './backend.js';
import UserMenu from './user-menu.js';
import State from './state.js';

export default class Router {
  static start() {
    this.elemCache = new Map();
    // TODO: Check on load if we have valid credentials.
    // TODO: Maybe use session ticket from API (after implementing it in API...)
    window.addEventListener('popstate', (event) => { console.debug(event); this.route() });
    this.route();
  }

  static async route(urlPath, msg, msgKlass='notice') {
    try {
      if (urlPath) {
        console.debug(`pushing '#${urlPath}' to history`);
        history.pushState({}, urlPath, `#${urlPath}`);
      } else {
        urlPath = window.location.hash;
      }
      if (urlPath[0] === '#') {
        urlPath = urlPath.slice(1);
      }

      if (msg) {
        Notifier.show(msgKlass, msg);
      } else {
        Notifier.clear();
      }

      // Don't allow the user to see cached data unless they are authenticated.
      if (urlPath !== 'login') {
        if (! Backend.hasCredentials()) {
          return this.route('login');
        }
      }
      
      let cacheHit = false;
      for (let [path, elem] of this.elemCache) {
        if (path === urlPath) {
          elem.show();
          cacheHit = true;
        } else {
          elem.hide();
        }
      }
      if (cacheHit) { return }

      const thing = await this.callRenderer(urlPath);
      if (thing instanceof HTMLElement) {
        this.elemCache.set(urlPath, thing);
      }
    } catch (exc) {
      console.error(exc);
      Notifier.show('error', 'An unexpected problem occurred, please try again later');
    }
  }

  static callRenderer(urlPath) {
    // Split URL into parts and filter out empty segments.
    const urlParts = urlPath.split('/').filter((part) => part);

    // Check this early to enable running other code for all other paths.
    switch(urlParts[0]) {
      case 'login':
        Backend.clearCredentials();
        return LoginController.show();
      case 'logout':
        Backend.clearCredentials();
        return this.route('login', 'You have been logged out!');
    }

    // Any other URL that doesn't start with 'lists' is unknown.
    if (urlParts[0] !== 'lists') {
      return this.route('lists');
    }

    this.userMenu = UserMenu.show(State.get('emailaddr'));

    // From here on we assume that urlParts[0] === 'lists'.
    switch (urlParts[1]) {
      case undefined:
        return ListsController.index();
      default:
        const listname = urlParts[1];
        switch (urlParts[2]) {
          case undefined:
            return this.route(`/lists/${listname}/subscriptions`);
          case 'edit':
            return ListsController.edit(listname);
          case 'subscriptions':
            switch(urlParts[3]) {
              case undefined:
                return SubscriptionsController.index(listname);
              case 'fresh':
                return SubscriptionsController.fresh(listname);
              default:
                const email = urlParts[3];
                switch(urlParts[4]) {
                  case 'edit':
                    return SubscriptionsController.edit(listname, email);
                  default:
                    return SubscriptionsController.show(listname, email);
                }
            }
          case 'keys':
            switch (urlParts[3]) {
              case undefined:
                return KeysController.index(listname);
              case 'fresh':
                return KeysController.fresh(listname);
              default:
                const fingerprint = urlParts[3];
                switch(urlParts[4]) {
                  case 'download':
                    return KeysController.download(listname, fingerprint);
                  default:
                    return KeysController.show(listname, fingerprint);
                }
            }
        }
    }
  }
}

