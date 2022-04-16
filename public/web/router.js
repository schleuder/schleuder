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
    this.loadingIcon = document.getElementById('loading-icon');
    this.loadingIcon.hide();
    this.elemCache = new Map();
    // TODO: Check on load if we have valid credentials.
    // TODO: Maybe use session ticket from API (after implementing it in API...)
    window.addEventListener('popstate', (event) => { console.debug(event); this.route() });
    this.route();
  }

  static async route(urlPath, msg, msgKlass='notice') {
    try {
      this.loadingIcon.show();
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
      if (exc instanceof TypeError && exc.message.slice(0, 12) === 'NetworkError') {
        Notifier.show('error', 'Could not connect to server, please check your network connection or try again later!');
      } else {
        Notifier.show('error', 'An unexpected problem occurred, please try again later');
      }
    } finally {
      this.loadingIcon.hide();
    }
  }

  // TODO: set page title
  static async callRenderer(urlPath) {
    // Split URL into parts and filter out empty segments.
    const urlParts = urlPath.split('/').filter((part) => part);

    // Check this early to enable running other code for all other paths.
    switch(urlParts[0]) {
      case 'login':
        Backend.clearCredentials();
        document.querySelector('form[is="login-form"]').show();
        return true;
      case 'logout':
        Backend.clearCredentials();
        this.userMenu.remove();
        this.userMenu = undefined;
        this.elemCache.forEach((view) => view.remove());
        this.elemCache.clear();
        return this.route('login', 'You have been logged out!');
    }

    // Any other URL that doesn't start with 'lists' is unknown.
    if (urlParts[0] !== 'lists') {
      return this.route('lists');
    }

    if (! this.userMenu) {
      // Use Promise-syntax to allow code to carry on.
      UserMenu.show(State.get('emailaddr'))
        .then((elem) => this.userMenu = elem);
    }

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
              case 'new':
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

