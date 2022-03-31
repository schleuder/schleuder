export default class NotiFier extends HTMLElement {
  static container = document.querySelector('#noti-fiers')

  constructor(msgType, msg) {
    super()
    this.className = msgType;
    this.textContent = msg;
    this.constructor.container.append(this);
  }
  
  
  static notice(msg) {
    return new this("notice", msg)
  }

  static error(msg) {
    return new this("error", msg)
  }

  static show(msgType, msg) {
    return new this(msgType, msg)
  }

  static clearAll() {
    this.container.childNodes.forEach((el) => el.remove())
  }
}

customElements.define("noti-fier", NotiFier)
