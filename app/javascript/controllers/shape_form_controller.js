import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "shapeInput"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selected = this.selectedShape()

    this.groupTargets.forEach((group) => {
      const allowed = group.dataset.allowedShapes.split(" ")
      group.hidden = !allowed.includes(selected)
    })
  }

  selectedShape() {
    const checked = this.shapeInputTargets.find((input) => input.checked)
    return checked ? checked.dataset.shapeName : null
  }
}
