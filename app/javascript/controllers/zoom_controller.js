import { Controller } from "@hotwired/stimulus"
import Panzoom from "@panzoom/panzoom"

export default class ZoomController extends Controller {
  static targets = ["image"]

  connect() {
    this.panzoom = Panzoom(this.imageTarget, {
      maxScale: 5,
      minScale: 0.5,
      contain: "outside"
    })

    this.imageTarget.parentElement.addEventListener("wheel", this.panzoom.zoomWithWheel)
  }

  disconnect() {
    this.imageTarget.parentElement.removeEventListener("wheel", this.panzoom.zoomWithWheel)
    this.panzoom.destroy()
  }

  zoomIn() {
    this.panzoom.zoomIn()
  }

  zoomOut() {
    this.panzoom.zoomOut()
  }

  reset() {
    this.panzoom.reset()
  }
}
