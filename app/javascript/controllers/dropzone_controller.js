import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zone", "input", "prompt", "preview"]

  dragover(event) {
    event.preventDefault()
    this.zoneTarget.classList.add("is-dragover")
  }

  dragleave(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("is-dragover")
  }

  drop(event) {
    event.preventDefault()
    this.zoneTarget.classList.remove("is-dragover")

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.inputTarget.files = files
      this.showPreview(files[0])
    }
  }

  click() {
    this.inputTarget.click()
  }

  preview() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.showPreview(file)
    }
  }

  showPreview(file) {
    this.promptTarget.style.display = "none"
    this.previewTarget.style.display = "block"

    if (file.type.startsWith("image/")) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.innerHTML = `
          <figure class="image is-128x128" style="margin: 0 auto;">
            <img src="${e.target.result}" alt="Preview" style="object-fit: cover;">
          </figure>
          <p class="has-text-centered mt-2">${file.name}</p>
        `
      }
      reader.readAsDataURL(file)
    } else {
      this.previewTarget.innerHTML = `<p class="has-text-centered">${file.name}</p>`
    }
  }
}
