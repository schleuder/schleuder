import {a} from "../hyper.js"

export default class ActionLink extends HTMLElement {
  constructor(url, content) {
    super()
    this.append(
      a({href: url}, content)
    )
  }
}

customElements.define('action-link', ActionLink)
