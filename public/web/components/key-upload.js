import BaseComp from "./base-comp.js"
import Backend from "../backend.js"
import SelectField from '../select-field.js';
import {keyUploadFile, keyUploadText, keyUploadSpacer} from "../hyper.js"

export default class KeyUpload extends HTMLElement {
  finished = Promise.resolve();

  constructor(listname, withSelection=false) {
    super();

    if (withSelection) {
      this.finished = Backend.fetch(listname, "keys")
        .then((keys) => {
          const keyOptions = {none: "none"}
          keys.forEach((key) => keyOptions[key.fingerprint] = key.key_summary)
          this.prepend(new SelectField("subscription-key", "Select a present key", null, false, keyOptions), keyUploadSpacer())
        })
    }

    this.append(keyUploadFile(), keyUploadSpacer(), keyUploadText())
  }
}

customElements.define("key-upload", KeyUpload)
