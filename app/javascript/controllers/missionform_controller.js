import { Controller } from "@hotwired/stimulus"

// Toggles mission-form fields by type. Photo-proof missions (review /
// social_share) are single-submission (goal forced to 1, goal field hidden);
// social_share also reveals the per-platform points block.
export default class extends Controller {
  static targets = ["type", "goalWrap", "platforms"]

  connect() { this.typeChanged() }

  typeChanged() {
    const t = this.typeTarget.value
    const photoProof = t === "review" || t === "social_share"

    if (this.hasGoalWrapTarget) {
      this.goalWrapTarget.hidden = photoProof
      const goal = this.goalWrapTarget.querySelector("input")
      if (goal && photoProof) goal.value = 1
    }
    if (this.hasPlatformsTarget) {
      this.platformsTarget.hidden = t !== "social_share"
    }
  }
}
