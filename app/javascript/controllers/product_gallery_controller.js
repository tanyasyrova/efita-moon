import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mainImage", "thumbnail"]

  select(event) {
    const thumbnail = event.currentTarget

    if (!this.hasMainImageTarget) return

    this.mainImageTarget.src = event.params.src
    this.mainImageTarget.alt = event.params.alt

    this.thumbnailTargets.forEach((button) => {
      button.setAttribute("aria-pressed", button === thumbnail ? "true" : "false")
    })
  }
}
