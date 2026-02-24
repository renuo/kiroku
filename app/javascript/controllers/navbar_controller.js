import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const target = document.getElementById(this.element.dataset.target)
    this.element.classList.toggle("is-active")
    target.classList.toggle("is-active")
  }
}
