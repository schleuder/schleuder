export default class Notifier {
  static elem = document.querySelector('#notifier');
  
  static show(klass, msg) {
    this.elem.className = klass;
    this.elem.textContent = msg;
    this.elem.show();
  }

  static clear() {
    this.elem.textContent = '';
    this.elem.className = '';
    this.elem.hide();
  }
}
