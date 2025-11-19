// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"


document.addEventListener('DOMContentLoaded', function() {
  function updateSettingsButtonState() {
    const consentPersonal = document.getElementById('consent_personal');
    const consentOffer = document.getElementById('consent_offer');
    const btn = document.querySelector('.settings-button');
    if (!btn) return;
    const enabled = consentPersonal.checked && consentOffer.checked;
    btn.disabled = !enabled;
    if (btn.disabled) {
      btn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      btn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  function settingsButtonClickHandler(e) {
    const consentPersonal = document.getElementById('consent_personal');
    const consentOffer = document.getElementById('consent_offer');
    if (!(consentPersonal && consentOffer && consentPersonal.checked && consentOffer.checked)) {
      e.preventDefault();
    }
  }

  const personalCb = document.getElementById('consent_personal');
  const offerCb = document.getElementById('consent_offer');
  const btn = document.querySelector('.settings-button');
  if (personalCb && offerCb && btn) {
    personalCb.addEventListener('change', updateSettingsButtonState);
    offerCb.addEventListener('change', updateSettingsButtonState);
    btn.addEventListener('click', settingsButtonClickHandler);
    updateSettingsButtonState();
  }
});