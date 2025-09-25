// Set launch date (adjust as needed)
const launchDate = new Date('2025-12-31T00:00:00').getTime();

function updateCountdown() {
    const now = new Date().getTime();
    const distance = launchDate - now;

    if (distance > 0) {
        const days = Math.floor(distance / (1000 * 60 * 60 * 24));
        const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((distance % (1000 * 60)) / 1000);

        document.getElementById('days').textContent = String(days).padStart(2, '0');
        document.getElementById('hours').textContent = String(hours).padStart(2, '0');
        document.getElementById('minutes').textContent = String(minutes).padStart(2, '0');
        document.getElementById('seconds').textContent = String(seconds).padStart(2, '0');
    } else {
        // Countdown finished
        document.getElementById('countdown').innerHTML = '<h2>We\'re Live!</h2>';
    }
}

// Update countdown every second
setInterval(updateCountdown, 1000);

// Initial call
updateCountdown();

// Handle email notification
document.getElementById('notify-btn').addEventListener('click', function() {
    const email = document.getElementById('email').value;
    
    if (email && isValidEmail(email)) {
        // Here you would typically send the email to your backend
        // For now, we'll just show a success message
        alert('Thank you! We\'ll notify you when we launch.');
        document.getElementById('email').value = '';
    } else {
        alert('Please enter a valid email address.');
    }
});

// Email validation function
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Handle Enter key in email input
document.getElementById('email').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        document.getElementById('notify-btn').click();
    }
});