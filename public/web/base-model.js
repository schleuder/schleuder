import Backend from "./backend.js";

export default class BaseModel {
  constructor(attribs) {
    for (const attribName of Object.keys(attribs)) {
      this[attribName] = attribs[attribName];
    }
  }

  static async _load(...urlParts) {
    const listname = urlParts[0];
    const attributes = await Backend.fetch(this._makeUrl(urlParts))
    return this._instantiate(attributes, listname);
  }

  static async _loadAll(...urlParts) {
    const listname = urlParts[0];
    const data = await Backend.fetch(this._makeUrl(urlParts)) 
    return data.map((attributes) => this._instantiate(attributes, listname))
  }

  static _makeUrl(parts) {
    return `/lists/${parts.join("/")}.json`
  }

  static _instantiate(attributes, listname) {
    if (listname) {
      return new this({...attributes, listname})
    } else {
      return new this(attributes)
    }
  }

}


