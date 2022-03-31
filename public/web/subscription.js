import BaseModel from "./base-model.js";

export default class Subscription extends BaseModel {
  // TODO: Make API add the listname to the data (additionally to the list-id)

  static async load(listname, email) {
    return this._load(listname, "subscriptions", email)
  }

  static async loadAll(listname) {
    return this._loadAll(listname, "subscriptions")
  }

  get url() {
    return `#lists/${this.listname}/subscriptions/${this.email}`
  }
}
