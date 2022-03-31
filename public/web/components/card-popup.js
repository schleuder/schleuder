import {div} from "../hyper.js";
import CardIcon from "./card-icon.js";

export default class CardPopup extends HTMLElement {
  constructor(icon, content) {
    super();
    this.append(new CardIcon(icon), div({class: `card-popup-text`}, content));
  }
}

customElements.define('card-popup', CardPopup)
