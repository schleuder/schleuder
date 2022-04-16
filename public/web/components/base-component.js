export default class BaseComponent extends HTMLElement {
  _wrapper = null;

  get wrapper() {
    if (! this._wrapper) {
      this._wrapper = this.makeElem('div', {class: this.nodeName.toLocaleLowerCase()});
    }
    return this._wrapper;
  }

  get name() {
    return this.getAttribute('name');
  }

  get required() {
    return !! this.getAttribute('required');
  }

  mount(...elems) {
    for (const elem of elems) {
      if (elem) {
        this.wrapper.appendChild(elem);
      }
    }
    this.insertAdjacentElement('beforebegin', this.wrapper);
  }

  makeInput(attribs) {
    attribs ||= {}
    return this.makeElem('input', {type: this.type, id: this.id, required: this.required, ...attribs});
  }

  makeLabel() {
    const label = this.makeElem('label', {for: this.name}, this.label);
    if (this.required) {
      const abbr = this.makeElem('abbr', {class: "required-hint", title: "This field is required"}, '*');
      label.appendChild(abbr);
    }
    return label;
  }

  makeUsage() {
    const usageText = this.getAttribute('usage');
    if (usageText) {
      return this.makeElem('small', {class: 'usage'}, usageText);
    }
  }

  makeElem(kind, attributes, textContent) {
    const elem = document.createElement(kind);
    if (attributes) {
      for (const key of Object.keys(attributes)) {
        elem.setAttribute(key, attributes[key]);
      }
    }
    if (textContent) {
      elem.textContent = textContent;
    }
    return elem;
  }
}
