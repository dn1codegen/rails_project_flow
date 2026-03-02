import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "image", "overlay", "overlayImage", "description", "counter", "prevButton", "nextButton" ]

  connect() {
    this.currentIndex = null
    this.boundBeforeCache = this.beforeCache.bind(this)
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)

    this.overlayTarget.hidden = true
    this.unlockPageScroll()
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
    this.unlockPageScroll()
  }

  open(event) {
    const index = this.imageTargets.indexOf(event.currentTarget)
    if (index === -1) return

    if (this.isOpen && this.currentIndex === index) {
      this.close()
      return
    }

    this.currentIndex = index
    this.overlayTarget.hidden = false
    this.lockPageScroll()
    this.renderCurrentImage()
  }

  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (!this.isOpen) return

    this.overlayTarget.hidden = true
    this.overlayImageTarget.removeAttribute("src")
    this.overlayImageTarget.setAttribute("alt", "")
    this.descriptionTarget.hidden = true
    this.descriptionTarget.textContent = ""
    this.currentIndex = null
    this.unlockPageScroll()
  }

  previous(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (!this.isOpen || !this.hasMultipleImages) return

    this.currentIndex = (this.currentIndex - 1 + this.imageTargets.length) % this.imageTargets.length
    this.renderCurrentImage()
  }

  next(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (!this.isOpen || !this.hasMultipleImages) return

    this.currentIndex = (this.currentIndex + 1) % this.imageTargets.length
    this.renderCurrentImage()
  }

  handleKeydown(event) {
    if (!this.isOpen) return

    if (event.key === "Escape") {
      this.close()
    } else if (event.key === "ArrowLeft") {
      this.previous()
    } else if (event.key === "ArrowRight") {
      this.next()
    }
  }

  backdropClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  scroll(event) {
    if (!this.isOpen || !this.hasMultipleImages) return

    event.preventDefault()

    if (event.deltaY > 0 || event.deltaX > 0) {
      this.next()
    } else if (event.deltaY < 0 || event.deltaX < 0) {
      this.previous()
    }
  }

  get isOpen() {
    return !this.overlayTarget.hidden
  }

  get hasMultipleImages() {
    return this.imageTargets.length > 1
  }

  renderCurrentImage() {
    const selectedImage = this.imageTargets[this.currentIndex]
    if (!selectedImage) return

    this.overlayImageTarget.src = selectedImage.dataset.lightboxUrl
    this.overlayImageTarget.alt = selectedImage.dataset.lightboxAlt || "Project change image"
    this.renderDescription(selectedImage.dataset.lightboxDescription)
    this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.imageTargets.length}`

    if (this.hasMultipleImages) {
      this.prevButtonTarget.hidden = false
      this.nextButtonTarget.hidden = false
    } else {
      this.prevButtonTarget.hidden = true
      this.nextButtonTarget.hidden = true
    }
  }

  lockPageScroll() {
    document.body.classList.add("lightbox-open")
  }

  unlockPageScroll() {
    document.body.classList.remove("lightbox-open")
  }

  renderDescription(description) {
    const cleanedDescription = (description || "").trim()

    if (cleanedDescription === "") {
      this.descriptionTarget.hidden = true
      this.descriptionTarget.textContent = ""
      return
    }

    this.descriptionTarget.hidden = false
    this.descriptionTarget.textContent = cleanedDescription
  }

  beforeCache() {
    this.close()
  }
}
