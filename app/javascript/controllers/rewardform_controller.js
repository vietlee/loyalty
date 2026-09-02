import { Controller } from "@hotwired/stimulus"

// Keep the reward "Giá trị / Đơn vị" fields consistent with the chosen type so
// a % discount can't be entered as a VND amount by mistake.
export default class extends Controller {
  static targets = ["kind", "unit", "value", "valueLabel"]

  connect() { this.syncLabel() }

  kindChanged() {
    const k = this.kindTarget.value
    if (k === "discount") this.unitTarget.value = "percent"
    else if (k === "voucher") this.unitTarget.value = "vnd"
    else if (k === "gift") this.unitTarget.value = "item"
    this.syncLabel()
  }

  syncLabel() {
    const map = {
      vnd:     ["Giá trị (đ)", "VD: 50000"],
      percent: ["Giá trị (%)", "VD: 10"],
      item:    ["Số lượng",    "VD: 1"],
    }
    const [label, ph] = map[this.unitTarget.value] || ["Giá trị", ""]
    if (this.hasValueLabelTarget) this.valueLabelTarget.textContent = label
    if (this.hasValueTarget) this.valueTarget.placeholder = ph
  }
}
