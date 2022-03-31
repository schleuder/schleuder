import {div} from "../hyper.js";
import CardIcon from "./card-icon.js";

export default class IndexCard extends HTMLElement {
  constructor(icon, content) {
    super();
    this.append(new CardIcon(icon), div({class: 'card-text'}, content));
  }
}

customElements.define('index-card', IndexCard)
