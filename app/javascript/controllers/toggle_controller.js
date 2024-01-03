import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "menu" ]
  static values = {isOpen: { type: Boolean, default: false }}

