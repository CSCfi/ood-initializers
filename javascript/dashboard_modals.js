import {
  setModals,
  toggleModal
} from "/assets/modules/modals.js";

$(function() {
  const container = document.createElement("div");
  container.id = "modal-container";
  document.body.appendChild(container);
  setModals();

  const cookiePolicyButton = document.getElementById("cookie-policy-toggle");
  cookiePolicyButton.addEventListener("click", () => toggleModal("cookie-modal"));

  const accessibilityStatementButton = document.getElementById("accessibility-statement-toggle");
  accessibilityStatementButton.addEventListener("click", () => toggleModal("accessibility-modal"));
})
