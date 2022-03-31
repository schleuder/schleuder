import BaseModel from "./base-model.js"

export default class Key extends BaseModel {
  static async load(listname, fingerprint) {
    return this._load(listname, "keys", fingerprint)
  }

  static async loadAll(listname) {
    return this._loadAll(listname, "keys")
  }

  get url() {
    return `#lists/${this.listname}/keys/${this.fingerprint}`;
  }
}
