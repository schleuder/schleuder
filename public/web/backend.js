import State from './state.js';

export default class Backend {
  static storeCredentials(emailaddr, password) {
    State.set('emailaddr', emailaddr);
    State.set('c', btoa(`${emailaddr}:${password}`));
  }

  static clearCredentials() {
    State.clear('emailaddr');
    State.clear('c');
  }

  static hasCredentials() {
    return !!State.get('c');
  }

  static async checkCredentials(emailaddr, password) {
    try {
      this.storeCredentials(emailaddr, password);
      const result = await this.fetch('/version.json');
      if (result instanceof Error) {
        this.clearCredentials(emailaddr, password);
        return false;
      } else {
        return true;
      }
    } catch (exc) {
      this.clearCredentials();
      console.error(exc);
      Notifier.show(exc.message);
    }
  }

  static async fetch(url) {
    const headers = {};
    const credentials = State.get('c');
    if (! credentials) {
      throw new Error("No credentials in State, cannot authenticate to API!");
    }
    headers["Authorization"] = `Basic ${credentials}`;
    console.debug(`Fetching '${url}' from API`);
    const response = await fetch(url, {headers: headers});
    let result;
    try {
      result = await response.json();
    } catch(exc) {
      return exc;
    }
    if (response.ok) {
      return result.data;
    } else {
      return new Error(result.error);
    }
  }
}
