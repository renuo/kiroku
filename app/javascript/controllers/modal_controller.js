import { Controller } from "@hotwired/stimulus"

export default class ModalController extends Controller {
  open(event) {
    if (event.target.closest("[data-no-modal]")) return
    document.getElementById(event.params.dialogId).showModal()
  }
}
