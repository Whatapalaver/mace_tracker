import { Controller } from "@hotwired/stimulus"

// Auto-submitting filter forms (selects/radios/checkboxes that resubmit on change) reload the
// full page, which otherwise resets scroll to the top — jarring when the control being changed
// is halfway down a long page. Saves scroll position right before submit and restores it once
// the reloaded page connects.
const STORAGE_KEY = "scrollPreservingFormScrollY"

export default class extends Controller {
  connect() {
    const saved = sessionStorage.getItem(STORAGE_KEY)
    if (saved === null) return

    sessionStorage.removeItem(STORAGE_KEY)
    const y = parseInt(saved, 10)

    // Charts on this page render asynchronously and expand the page's height afterward, so
    // scrolling once on connect can clamp short of the saved position if it fires first.
    // Re-applying a couple of times shortly after covers that without depending on any one
    // exact render-completion event.
    window.scrollTo(0, y)
    setTimeout(() => window.scrollTo(0, y), 100)
    setTimeout(() => window.scrollTo(0, y), 300)
  }

  submit() {
    sessionStorage.setItem(STORAGE_KEY, window.scrollY)
    this.element.requestSubmit()
  }
}
