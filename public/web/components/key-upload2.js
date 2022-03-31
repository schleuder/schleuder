import Backend from "../backend.js"
import SelectField from '../select-field.js';
import {div, keyUploadFile, keyUploadText, keyUploadSpacer} from "../hyper.js"

export default class KeyUpload {
  finished = Promise.resolve();
  listname;
  selectElem = null;

  constructor(listname) {
    this.listname = listname;
  }

  render(withSelection=false) {
    // TODO: limit upload file/text size
    const elem = div({class: "key-upload"})
    if (withSelection) {
      this.finished = Backend.fetch(this.listname, "keys")
        .then((keys) => {
          const keyOptions = {none: "none"}
          keys.forEach((key) => keyOptions[key.fingerprint] = key.key_summary)
          this.selectElem = new SelectField("subscription-key", "Select a present key", null, false, keyOptions), keyUploadSpacer()
          elem.prepend(this.selectElem, keyUploadSpacer());
        })
    }

    this.uploadFile = keyUploadFile()
    this.uploadText = keyUploadText()
    elem.append(keyUploadFile(), keyUploadSpacer(), keyUploadText())
    return elem
  }

  getSelection() {
    return this.selectElem.selectedOptions?.at(0)
  }

  getInput() {
    if (this.uploadText.value) {
      return this.uploadText.value
    } else if (this.uploadFile.files[0]) {
      const file = this.uploadFile.files[0]
      const reader = new FileReader()
      // Returns the file's contents encoded with Base64
      return reader.readAsDataURL(file).replace(/^data:.*?\/.*?;base64,/, '');
    } else {
      return null
    }
  }
}
