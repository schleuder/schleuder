import {ul, li, a, img} from './hyper.js';

export default class UserMenu extends HTMLElement {
  constructor(emailadress) {
    super()
    this.append(ul(
      li({class: "user-emailaddress"}, emailadress),
      li(
        a({class:  'mylists-link', href: '#lists'},
          img({src: "./images/house.svg", alt: "House icon"}),
          "My lists"
        )
      ),
      li(
        a({class: 'logout-link', href: '#logout'},
          img({src: "./images/log-out.svg", alt: "House icon"}),
          "Logout"
        )
      )
    ))
  }
}

customElements.define("user-menu", UserMenu)
