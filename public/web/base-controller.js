import './html-element.js';

export default class BaseController {
  static elem(selector) {
    const el = document.querySelector(selector);
    if (!el) {
      throw new Error(`No element found for selector '${selector}'`);
    }
    return el;
  }
}
