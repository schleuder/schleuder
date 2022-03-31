import Backend from "./backend.js";
import BaseModel from "./base-model.js";

export default class List extends BaseModel {
  // TODO: Extend API to provide more details
  // TODO: get listname as attribute from API (list_id doesn't help)

  static async load(listname) {
    return this._load(`/lists/${listname}.json`)
  }

  static async loadAll() {
    // Can't use _loadAll, because /lists.json is only an array of strings, not one of objects
    const listnames = await Backend.fetch(`/lists.json`)
    return listnames.map((listname) => new this({listname}));
  }

  get url() {
    return `#lists/${this.listname}`;
  }
}
