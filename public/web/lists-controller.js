import BaseController from './base-controller.js';
import List from './list.js';
//import ListIndex from './components/list-index.js';
import {h1, ul, li, a} from './hyper.js';

export default class ListsController extends BaseController {
  static async index() {
    const lists = await List.loadAll()
    return div({class: 'list-index'}, [
      h1('Your lists'),
      ul(lists.map((list) =>
          li( a({href: `#lists/${list.listname}`}, list.listname) )
        )
      )
    ]);
  }

  static async edit(listname) {
    const instance = new this()
    const list = await instance.get(`/lists/${listname}.json`);
    return instance.bakeFromTemplate('listEdit', {list});
  }
}
