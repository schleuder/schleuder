import {object} from "../hyper.js"

export default class PlusSign extends HTMLElement {
  constructor() {
    super()
    this.append(object({type: "image/svg+xml", data: "./images/plus.svg"}, "+"))
  }
}

customElements.define('plus-sign', PlusSign)
