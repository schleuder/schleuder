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

  div(className) {
    return this.makeElem("div", className);
  }

  makeElem(kind, className) {
    const elem = document.createElement(kind);
    if (className) {
      elem.className = className;
    }
    return elem;
  }

  bakeFromTemplate(id, replacements) {
    const wrapper = this.div("view");
    if (this.listname) {
      wrapper.appendChild(this.makeListMenu(id));
    }
    wrapper.appendChild(Template.fromId(id).render(replacements));
    document.body.appendChild(wrapper);
    return wrapper;
  }

  makeListMenu(current) {
    const opts = {
      listname: this.listname
    };
    opts[`${current}IsCurrent`] = true;
    return Template.fromId('list-menu').render(opts);
  }
}
