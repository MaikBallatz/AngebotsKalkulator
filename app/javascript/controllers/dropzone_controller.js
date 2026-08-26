import { Controller } from "@hotwired/stimulus"

// Drag-and-drop convenience for a file input. Pure UI interaction — the
// underlying <input type="file"> still works with a plain click, so the
// form functions without JavaScript too.
export default class extends Controller {
  static targets = ["input"]

  dragover(event) {
    event.preventDefault()
    this.element.classList.add("bg-muted")
  }

  dragleave() {
    this.element.classList.remove("bg-muted")
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("bg-muted")
    this.inputTarget.files = event.dataTransfer.files
  }
}
