# MediScan App

MediScan is a web application that helps users identify medicines by taking or uploading a photo. It then displays detailed information about the medicine, including what it does, how to take it, precautions, and more.

## Features
- **Take or upload a photo:** Use your device camera or upload an image to identify a medicine.
- **Medicine details:** Shows information such as name, manufacturer, description, how it works, dosage, administration, and safety precautions.
- **Personal profile:** (Planned) Users will be able to log in and personalize their experience.
- **My Medications:** Save medicines to a personal list for easy tracking.
- **Modern, mobile-friendly design:** Built for easy use on any device.

## Tech Stack
- **Frontend:** React + Vite
- **Styling:** Tailwind CSS
- **Icons:** Lucide React
- **State:** React hooks (future: may use Zustand or Context)
- **Testing:** (Planned) Vitest for unit tests, Playwright for end-to-end tests

## How to Run the App
1. **Install dependencies:**
   ```bash
   npm install
   ```
2. **Start the development server:**
   ```bash
   npm run dev
   ```
3. Open your browser to [http://localhost:5173](http://localhost:5173) to use the app.

## Current Status
- The app is running with a sample user interface and mock medicine data.
- Real medicine identification and user accounts are planned for future updates.

## Future Improvements
- Connect to a real medicine database or AI for live identification.
- Implement secure user authentication.
- Persist user's medication list (locally or with a backend).
- Add accessibility and localization support.
- Complete unit and end-to-end test coverage.

---

**MediScan is designed to make it easy for anyone to identify and learn about medicines using just a photo, and to keep track of their medications—all from an easy-to-use web app.**
