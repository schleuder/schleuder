import BaseComp from "./base-comp.js"
import KeyUpload from "./key-upload.js"
import {h1, button, fieldset, legend} from "../hyper.js"

export default class KeyForm extends BaseComp {
  constructor(listname) {
    super()
    this.append(h1("Upload key"))
    this.append(
      fieldset(
        legend("Upload a new key"), 
        new KeyUpload(listname)
      ),
      button({type: "button", onClick: () => this.upload()}, "Upload")
    )
    this.finished()
  }

  upload() {
    console.info("Soon…")
  }
}

customElements.define("key-form", KeyForm)
