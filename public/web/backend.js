import State from './state.js';
import NotiFier from './noti-fier.js'

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
      NotiFier.error(exc.message);
    }
  }

  static async fetch(...urlParts) {
    const headers = {};
    const credentials = State.get('c');
    if (! credentials) {
      throw new Error("No credentials in State, cannot authenticate to API!");
    }
    headers["Authorization"] = `Basic ${credentials}`;
    let url;
    // Prepend '/lists/' to relative URLs.
    if (urlParts.length === 1 && urlParts[0][0] === "/") {
      url = urlParts[0]
    } else {
      url = ["/lists", ...urlParts].join("/") + ".json"
    }
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
