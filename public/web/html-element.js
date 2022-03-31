HTMLElement.prototype.hide = function() {
  this.hidden = true;
  this.classList.add('hidden');
}

HTMLElement.prototype.show = function() {
  this.hidden = false;
  this.classList.remove('hidden');
}
