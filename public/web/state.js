export default class State {
  // sessionStorage is the default because it automatically clears data when
  // the tab is closed, which reduces the risk of leaking data.
  static storage = window.sessionStorage;
  static keyScope = 'SchleuderWeb.';

  static get(key, defaultValue) {
    try {
      const value = this.storage.getItem(this.scopedKey(key));
      if (value) {
        return JSON.parse(value);
      } else {
        return defaultValue;
      }
    } catch(e) {
      // Catch possible exceptions, e.g. due to localStorage not being available or being over quota.
      // TODO: Maybe try to check for the reason of the error?
      // <https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API#testing_for_availability>
      // could help.
      // On the other hand the calling code doesn't really care: if the value
      // is not present it has to get it from another source, no matter the
      // reason.
      return defaultValue;
    }
  }

  static set(key, value) {
    try {
      this.storage.setItem(this.scopedKey(key), JSON.stringify(value));
      return true;
    } catch(err) {
      return false;
    }
  }

  static clear(key) {
    try {
      this.storage.removeItem(this.scopedKey(key));
      return true;
    } catch(err) {
      return false;
    }
  }

  static clearAll() {
    try {
      this.storage.clear();
      return true;
    } catch(err) {
      return false;
    }
  }

  // Scope the key to our project to avoid collisions (in this localStorage
  // other data can be stored from the current domain).
  static scopedKey(key) {
    return this.keyScope + key;
  }
}
