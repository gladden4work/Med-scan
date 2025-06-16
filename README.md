# MediScan App

MediScan is a web application that helps users identify medicines by taking or uploading a photo. It then displays detailed information about the medicine, including what it does, how to take it, precautions, and more.

## Features
- **Take or upload a photo:** Use your device camera or upload an image to identify a medicine.
- **Medicine details:** Shows information such as name, manufacturer, description, how it works, dosage, administration, and safety precautions.
- **Personal profile & authentication:** Users can sign up and log in with Google or email/password (Supabase Auth).
- **My Medications:** Save medicines to a personal list for easy tracking.
- **Modern, mobile-friendly design:** Built for easy use on any device.

## Tech Stack
- **Frontend:** React + Vite
- **Styling:** Tailwind CSS
- **Icons:** Lucide React
- **State:** React hooks (future: may use Zustand or Context)
- **Testing:** (Planned) Vitest for unit tests, Playwright for end-to-end tests

## How to Run the App

After cloning the repo:

1. **Install dependencies for all parts:**
   ```bash
   npm install
   cd ..
   ```

2. **Start both frontend and backend together:**
   ```bash
   cd mediscan-app
   npm run dev:all
   ```
   This will:
   - Start the React frontend (Vite, default port 5173 or next available)
   - Start the backend server (Node.js, port 4000)

3. **Open your browser:**
   Go to the port shown in the terminal (e.g., [http://localhost:5173](http://localhost:5173) or [http://localhost:5174](http://localhost:5174)) to use the app.

4. **Authentication & Sign Up:**
   - On first visit, you can sign up for a new account using email/password or Google.
   - After signing up, check your email for a confirmation link (required by Supabase).
   - Once confirmed, you can log in and access medication features.
   - You can switch between sign in and sign up on the authentication page.

---

**Troubleshooting:**
- If you see errors about ports in use, close other dev servers or let Vite pick the next port.
- If backend fails with `require`/`import` errors, check `backend/package.json` for correct `type` (see "Lessons Learned" below).
- The legacy app is archived in `legacy-app/` and should not be used.

---

## Project Vision
MediScan is a web app for identifying medicines, supplements, and equipment from a photo. It provides details (use, dosage, safety, where to buy) and lets users track their medications. The app is mobile-first, modern, and privacy-aware.

## Tech Stack
- **Frontend:** React (Vite)
- **Backend:** Node.js (Express, proxy for Google Gemini AI)
- **Styling:** Tailwind CSS
- **Icons:** Lucide React
- **Authentication:** Supabase (Google OAuth, email/password sign in & sign up)
- **Hosting:** Cloudflare Pages + Workers
- **Image Processing:** Python/phash (future, via WASM)

## Lessons Learned
- **Node.js Module Types:** If backend fails with `require`/`import` errors, ensure `backend/package.json` matches your code style (`type: "module"` for ES modules, omit for CommonJS).
- **Concurrent Dev:** Use `npm run dev:all` for a seamless workflow.
- **Legacy Code:** All new work is in `mediscan-app/`; root-level legacy code is archived.

## Current Status
- The app now supports real user authentication (sign in & sign up with Supabase, Google/email).
- Medicine identification is available; user accounts and profile features are live.
- New users receive a confirmation email from Supabase when signing up.
- Medication tracking and additional features are in progress.

## Future Improvements
- Connect to a real medicine database or AI for live identification.
- Enhance authentication UX and error handling.
- Persist user's medication list (locally or with a backend).
- Add accessibility and localization support.
- Complete unit and end-to-end test coverage.

---

**MediScan is designed to make it easy for anyone to identify and learn about medicines using just a photo, and to keep track of their medications—all from an easy-to-use web app.**
