import {img} from "../hyper.js";

export default class CardIcon extends HTMLElement {
  constructor(iconName) {
    super();
    this.append(img({src: `./images/${iconName}.svg`, alt: `Icon showing ${iconName}`}))
  }
}

customElements.define('card-icon', CardIcon)
