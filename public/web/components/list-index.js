import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import {h1, ul, li} from '../hyper.js';

export default class ListIndex extends BaseComp {
  constructor() {
    super();
    this.append(h1('Your lists'))
    Backend.fetch() 
      .then((listnames) => {
        this.append(
          ul(listnames.map((listname) => li(this.linkTo(listname, [listname]))))
        )
        this.finished()
      })
  }
}

customElements.define('list-index', ListIndex)
