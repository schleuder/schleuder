import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import {h1, html} from '../hyper.js'

export default class KeyShow extends BaseComp {
  constructor(listname, fingerprint) {
    super(listname)
    this.append(h1(fingerprint))
    Backend.fetch(listname, "keys", fingerprint)
      .then((key) => {
        this.append(html("pre", key.ascii))
        this.finished()
      })
  }
}

customElements.define('key-show', KeyShow)
