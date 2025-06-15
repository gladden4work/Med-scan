# MediScan App – Unified Product & Engineering Plan

## Product Vision & User Journey

MediScan is a mobile-first app that allows users to identify medicines, supplements, and medical equipment by taking or uploading a photo. The app provides detailed information about the item, including its use, dosage, precautions, and purchasing options, and lets users track their own medications.

### User Flow
1. **Camera/Upload:** User takes or uploads a photo of a medicine/supplement/equipment.
2. **Preview:** User previews the photo before submitting.
3. **Results:** App shows the image, name, manufacturer, category (Medicine, Supplement, Equipment), and details:
   - What is this for?
   - How does it work?
   - Dosage (adult, teen, child)
   - Administration (eat/drink, etc.)
   - Precautions
   - Actions: "I'm taking this" (save to My Medication), Share (generate link), Where to buy (external link)
4. **No match:** If not found, user can report an issue.
5. **Authentication:** Users can log in with Google or email.
6. **My Medication:** Users can manage a list of their medications, including frequency (daily/weekly/monthly/as needed/no longer taking).
7. **Share Link:** Generates a public info page for sharing.

### Admin/Backend Features
- Admin web page to review requests, switch AI engine, view feedback, and monitor new signups.
- Backend optimizations: avoid duplicate queries (phash similarity), store uploaded images, handle "not a med" cases.

### Monetization
- In-app purchases (limit free scans, upsell for more)
- "Where to buy" links with UTM tracking
- Potential for ads

## Requirements & Infrastructure
| Area                 | Decision                                              |
| -------------------- | ----------------------------------------------------- |
| **Frontend**         | React (Vite)                                          |
| **Hosting**          | Cloudflare Pages + Workers                            |
| **Serverless API**   | Cloudflare Workers (TypeScript)                       |
| **Auth**             | Supabase Auth (email/social login, JWT support)       |
| **Budget**           | < USD 15/month                                        |
| **Image processing** | Python (phash, compiled to WASM for web)              |
| **Object storage**   | Cloudflare R2                                         |
| **Database**         | Cloudflare D1                                         |
| **React State**      | Tanstack Query                                        |
| **Share links**      | Tokenized public URL, read-only DB access             |
| **Scan limits**      | Supabase user ID                                      |
| **Error logging**    | Cloudflare Logpush                                    |

---

## Engineering Project Plan

## Notes
- Project: Medicine identification & management web app (React + Vite).
- Styling: Tailwind CSS v3; icons: `lucide-react`.
- AI: Google Gemini 2.5 Flash via a secure backend proxy.
- Core UI: Camera → Preview → Results, Profile, My Medications.
- Dev Environment: Frontend (Vite) and Backend (Express) run concurrently.

## Lessons Learned
- **Node.js Module Types**: When a Node.js backend server fails with module-related errors (`require is not defined` or `Cannot use import`), it's crucial to ensure consistency. The `backend/package.json` must include `"type": "module"` if the server code (`server.js`) uses ES Module `import` syntax. If it uses CommonJS `require()` syntax, `"type": "module"` must be removed. A mismatch between these two causes runtime errors.

## File Roles
- `plan.md`: This document, outlining project goals and tasks.
- `backend/server.js`: The Express backend server that proxies requests to the Google AI API, keeping the API key secure.
- `backend/.env`: Stores the secret `GOOGLE_API_KEY`.
- `backend/package.json`: Manages backend dependencies and scripts.
- `mediscan-app/src/App.jsx`: The main React component for the frontend UI and logic.
- `mediscan-app/package.json`: Manages frontend dependencies and scripts, including the `dev:all` script to run both servers.
- `.gitignore`: Specifies which files and folders Git should ignore, preventing secrets and unnecessary files from being committed.

## Task List

### Phase 1: Initial Setup & UI
- [x] Create Vite React project (`mediscan-app`).
- [x] Install & configure Tailwind CSS v3, PostCSS, Autoprefixer.
- [x] Install `lucide-react` icon package.
- [x] Replace boilerplate with full `MediScanApp` component.
- [x] Populate Results page with full medicine details UI.
- [x] Initialize Git repository and push to GitHub.
- [x] Write project README documentation.

### Phase 2: AI Integration & Backend
- [x] Install Google AI SDK and add client library.
- [x] Update `analyzeMedicine` to call Gemini with image input.
- [x] Set up simple backend to securely store Google API key and proxy requests.
- [x] Store Google API key in `.env` file.
- [x] Update frontend to use backend for AI analysis.
- [x] Create backend `package.json` and install dependencies.
- [x] Add `dev:all` script using concurrently to run both frontend and backend.
- [x] Add `.env` to `.gitignore`.

### Phase 3: Core Features & UX
- [ ] Replace mock image capture with real camera/file input handling.
- [ ] Configure Playwright & screenshot tooling (install browsers, set paths).
- [ ] Implement Profile page with authentication flow.
- [ ] Persist medications list (local storage or backend).
- [ ] Add unit & E2E tests; set up CI.

## Current Goal
Replace mock image capture with real camera/file input handling for better UX and mobile support.
