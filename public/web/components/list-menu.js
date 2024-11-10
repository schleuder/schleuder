import {div, ul, li, a, icon} from "../hyper.js";
import {t} from "../translations.js";

export default class ListMenu extends HTMLElement {
  constructor(listname, currentUrl) {
    super();
    this.listname = listname;
    this.currentUrl = currentUrl;

    const headline = div({class: "pageheadline"});
    this.append(headline);
    if (! listname) {
      headline.textContent = t("my_lists");
    } else {
      headline.textContent = this.listname;
      this.append(ul(
        this.makeItem(t("subscriptions"), 'subscriptions', "people"),
        this.makeItem(t("keys"), 'keys', "keyring"),
        this.makeItem(t("list_options"), 'edit', "wrench")
      ));
    }
  }

  makeItem(text, urlPart, iconName) {
    const url = `lists/${this.listname}/${urlPart}`;
    if (url === this.currentUrl) {
      return li(icon(iconName), text);
    } else {
      return li(a({href: `#${url}`}, icon(iconName), text))
    }
  }
}

customElements.define('list-menu', ListMenu)
