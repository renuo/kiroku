import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.classList.contains("flash-animate")) {
      this.timeout = setTimeout(() => this.dismiss(), 5000)
    }
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  close() {
    this.dismiss()
  }

  dismiss() {
    this.element.classList.add("flash-dismiss")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }
}
