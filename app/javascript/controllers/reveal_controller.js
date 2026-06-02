import { Controller } from "@hotwired/stimulus"

// Fades child elements marked with [data-reveal] in as they scroll into view.
// Pure IntersectionObserver, no animation libraries. Degrades to "show
// everything" when motion is reduced or the API is unavailable.
export default class extends Controller {
  connect() {
    this.items = Array.from(this.element.querySelectorAll("[data-reveal]"))
    if (this.items.length === 0) return

    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (reduceMotion || !("IntersectionObserver" in window)) {
      this.items.forEach((el) => el.classList.add("is-in"))
      return
    }

    // Gentle stagger so a grid cascades instead of popping in all at once.
    this.items.forEach((el, i) => {
      el.style.transitionDelay = `${Math.min(i, 6) * 60}ms`
    })

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return
          entry.target.classList.add("is-in")
          this.observer.unobserve(entry.target)
        })
      },
      { threshold: 0.1, rootMargin: "0px 0px -6% 0px" }
    )

    this.items.forEach((el) => this.observer.observe(el))
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
