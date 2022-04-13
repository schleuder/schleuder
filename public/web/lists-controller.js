import BaseController from './base-controller.js';
import Backend from './backend.js';

export default class ListsController extends BaseController {
  static async index() {
    // TODO: Extend API to provide more details
    const instance = new this()
    const listEmails = await instance.get('lists.json');
    const lists = listEmails.map((email) => { return {email} });
    return instance.bakeFromTemplate('listsIndex', {lists});
  }

  static async edit(listname) {
    const instance = new this()
    const list = await instance.get(`/lists/${listname}.json`);
    return instance.bakeFromTemplate('listEdit', {list});
  }
}
