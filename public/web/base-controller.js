import Template from './template.js';
import Backend from './backend.js';

export default class BaseController {
  listname;

  constructor(listname) {
    this.listname = listname;
  }

  async get(urlDetail) {
    return await Backend.fetch(this.url(urlDetail));
  }

  url(urlDetail) {
    if (this.listname) {
      return `/lists/${this.listname}/${urlDetail}`;
    } else {
      return `/${urlDetail}`;
    }
  }

  static elem(selector) {
    const el = document.querySelector(selector);
    if (!el) {
      throw new Error(`No element found for selector '${selector}'`);
    }
    return el;
  }
}
