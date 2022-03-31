import './html-element.js';

export default class Template {
  static bake(idOrNode, replacements) {
    let template;
    if (typeof(idOrNode) === 'string') {
      const selector = `template#${idOrNode}`;
      template = document.querySelector(selector);
    } else {
      template = idOrNode;
    }
    const fragment = template.content.cloneNode(true);
    const wrapper = document.createElement('div');
    wrapper.className = template.className;
    wrapper.appendChild(fragment);
    this.fill(wrapper, replacements);
    template.insertAdjacentElement('afterend', wrapper);
    return wrapper;
  }

  static fill(node, replacements) {
    if (node.nodeName === 'TEMPLATE') {
      if (node.attributes.for && replacements[node.attributes.for.value] instanceof Array) {
        const items = replacements[node.attributes.for.value];
        items.forEach((item) => Template.bake(node, {...item, ...replacements, cssClass: ''}));
      }
    }
    node.childNodes.forEach((childNode) => {
      if (childNode.nodeType === Node.TEXT_NODE) {
        if (childNode.nodeValue.includes('{')) {
          childNode.nodeValue = this.replace(childNode.nodeValue, replacements);
        }
      } else {
        this.fill(childNode, replacements);
      }
    });
    if (node.attributes) {
      for (const attr of node.attributes) {
        if (attr.value.includes('{')) {
          node.setAttribute(attr.name, this.replace(attr.value, replacements));
        }
      }
    }
    return node;
  }

  static replace(string, replacements) {
    return string.replace(/{(\S+?)}/g, (_, word) => {
      if (typeof(replacements[word]) !== 'undefined') {
        return replacements[word];
      } else {
        throw new Error(`Unavailable replacement key used in template: '${word}'`);
      }
    });
  }
}
