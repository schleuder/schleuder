export function makeElem(kind, attributes, textContent) {
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
