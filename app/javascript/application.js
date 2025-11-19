// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"


document.addEventListener('DOMContentLoaded', function() {
  function updateSettingsButtonState() {
    const consentPersonal = document.getElementById('consent_personal');
    const consentOffer = document.getElementById('consent_offer');
    const btn = document.querySelector('.settings-button');
    if (!btn) return;
    btn.disabled = !(consentPersonal.checked && consentOffer.checked);
    if (btn.disabled) {
      btn.classList.add('opacity-50', 'cursor-not-allowed');
    } else {
      btn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  const personalCb = document.getElementById('consent_personal');
  const offerCb = document.getElementById('consent_offer');
  if (personalCb && offerCb) {
    personalCb.addEventListener('change', updateSettingsButtonState);
    offerCb.addEventListener('change', updateSettingsButtonState);
    updateSettingsButtonState();
  }
});