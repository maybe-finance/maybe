import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["expenseCategories", "incomeCategories"]

    connect() {
        this.updateCategories()
    }

    updateCategories(event) {
        const natureField = this.element.querySelector('input[name="account_entry[nature]"]:checked')
        const natureValue = natureField ? natureField.value : 'outflow'

        if (natureValue === 'inflow') {
            this.expenseCategoriesTarget.classList.add('hidden')
            this.incomeCategoriesTarget.classList.remove('hidden')
        } else {
            this.expenseCategoriesTarget.classList.remove('hidden')
            this.incomeCategoriesTarget.classList.add('hidden')
        }
    }
}
