import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import {h1, div, span} from '../hyper.js'

export default class ListForm extends BaseComp {
  constructor(listname) {
    super(listname)
    this.append(h1("List options"))
    Backend.fetch(listname)
      .then((list) => {
        Object.keys(list).forEach((key) => {
          this.append(div(span(key), ": ", span(String(list[key]))))
        })
        this.finished()
      })
  }
}

customElements.define("list-form", ListForm)

