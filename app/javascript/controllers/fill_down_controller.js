import { Controller } from "@hotwired/stimulus"

// Leaving the first field copies its value into every other still-blank
// field in the group, so a uniform-reps session (e.g. 80 sets of 6 reps)
// doesn't require typing the same number 80 times. Fields already edited are
// left alone. Fires on "change" (blur), not "input", so a multi-digit value
// propagates once as a whole rather than one partial digit at a time.
export default class extends Controller {
  static targets = ["source", "field"]

  fill() {
    const value = this.sourceTarget.value
    if (value === "") return

    this.fieldTargets.forEach((field) => {
      if (field !== this.sourceTarget && field.value === "") field.value = value
    })
  }
}
