import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import {a, h1, ul, li} from '../hyper.js';
import {t} from '../translations.js'

export default class ListIndex extends BaseComp {
  constructor() {
    super();
    this.append(h1(t("your_lists")))
    Backend.fetch() 
      .then((listnames) => {
        this.append(
          ul(listnames.map((listname) => li(a({href: this.urlFor(listname)}, listname))))
        )
        this.finished()
      })
  }
}

customElements.define('list-index', ListIndex)
