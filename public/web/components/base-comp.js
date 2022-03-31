import {a} from '../hyper.js'

export default class BaseComp extends HTMLElement {
  listname = null;

  constructor(listname) {
    super()
    if (listname) {
      this.listname = listname;
    }
    this.loadingIcon = document.querySelector(".loading-icon")
    this.loadingIcon.classList.add("view-loading")
    this.loadingIcon.show()
  }

  finished() {
    this.loadingIcon.classList.remove("view-loading")
    this.loadingIcon.hide()
  }

  linkTo(text, urlParts) {
    return a({href: this.urlFor(urlParts)}, text)
  }

  urlFor(...parts) {
    return ["#lists", this.listname, ...parts.flat()].filter((item) => item).join("/")
  }
}
