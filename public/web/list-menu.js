export default class ListMenu {
  constructor(listname ) {

    this.attachShadow({mode: 'open'});
    this.listname = this.getAttribute('listname');
    if (!this.listname) {
      return;
    }
    const wrapper = this.div("list-menu");
    const headline = this.div("pageheadline");
    headline.textContent = this.listname;
    wrapper.appendChild(headline);
    const menuList = this.makeElem('ul');
    menuList.appendChild(this.menuItem('Subscriptions', 'subscriptions'));
    menuList.appendChild(this.menuItem('Keys', 'keys'));
    menuList.appendChild(this.menuItem('List options', 'edit'));
    wrapper.appendChild(menuList);
    this.shadow.appendChild(wrapper);
  }

  menuItem(text, urlPart) {
    const li = this.makeElem('li');
    if (this.getAttribute('current').toLocalLowerCase().trim() === text.toLocalLowerCase().trim()) {
      li.textContent = text;
    } else {
      const a = this.makeElem('a');
      a.setAttribute("href", `#lists/${this.listname}/${urlPart}`);
      a.textContent = text;
      li.appendChild(a);
    }
    return li;
  }

  div(className) {
    return this.makeElem("div", className);
  }

  makeElem(kind, className) {
    const elem = document.createElement(kind);
    if (className) {
      elem.className = className;
    }
    return elem;
  }

}
