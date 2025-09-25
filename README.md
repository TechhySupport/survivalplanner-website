# Coming Soon Website

A modern, responsive "Coming Soon" website built with HTML, CSS, and JavaScript.

## Features

- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Countdown Timer**: Dynamic countdown to launch date
- **Email Notification**: Visitors can sign up to be notified when the site launches
- **Modern UI**: Clean, gradient background with glassmorphism effects
- **Interactive Elements**: Hover effects and smooth animations

## Files

- `index.html` - Main HTML structure
- `styles.css` - CSS styling with responsive design
- `script.js` - JavaScript for countdown timer and email functionality

## Customization

### Change Launch Date
Edit the launch date in `script.js`:
```javascript
const launchDate = new Date('2025-12-31T00:00:00').getTime();
```

### Modify Colors
Update the gradient background in `styles.css`:
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Update Content
Change the heading and description in `index.html`:
```html
<h1>Coming Soon</h1>
<p>We're working hard to bring you something amazing. Stay tuned!</p>
```

## Usage

1. Open `index.html` in a web browser
2. The countdown will automatically start
3. Visitors can enter their email to be notified
4. The design is fully responsive and mobile-friendly

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge

## Notes

- The email notification feature currently shows an alert. To make it functional, you'll need to integrate with a backend service or email API.
- The countdown is set to December 31, 2025. Update this date as needed.
- All styling uses modern CSS features like `backdrop-filter` for glassmorphism effects.