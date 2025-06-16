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

## Current Status & Issues (June 2025)

**Project Status**: V2 conversion successful.

### Identified Issues:
1. **Frontend is hybrid v1/v2**: Current `mediscan-app/src/App.jsx` still shows "Enter Google API Key" field (v1 behavior)
2. **No backend integration**: Frontend makes direct Google AI calls instead of calling backend `/analyze` endpoint
3. **Legacy code mess**: `mediscan-app/legacy-app/` folder contains duplicate old code
4. **Port conflicts**: Backend cannot start on port 4000 (already in use)
5. **Missing unified startup script**: `dev:all` script is missing/broken

### Architecture Goal:
- **Frontend (v2)**: No API key input, calls backend `/analyze`, proper Supabase auth
- **Backend (v2)**: Secure API key handling, `/analyze` endpoint, CORS configured
- **Clean structure**: No legacy folders, unified startup process

## V2 Conversion & Cleanup Plan

### Phase 1: Update Documentation & Plan
- [x] Update `plan.md` with current state and v2 conversion plan
- [ ] Document file structure and responsibilities

### Phase 2: Clean Legacy Code
- [x] Remove entire `mediscan-app/legacy-app/` folder
- [x] Remove any duplicate/conflicting files
- [x] Verify clean project structure

### Phase 3: Convert Frontend to V2
- [x] Remove "Enter Google API Key" input field from UI
- [x] Replace direct Google AI calls with backend API calls
- [x] Update `analyzeMedicine` function to call `http://localhost:3001/analyze`
- [x] Add proper error handling for backend communication
- [x] Test Supabase authentication integration

### Phase 4: Fix Backend & Port Configuration
- [x] Resolve port 4000 conflict (kill process or change port)
- [x] Update backend to use port 3001 instead of 4000
- [x] Add environment variable for backend URL in frontend
- [x] Test backend `/analyze` endpoint

### Phase 5: Unified Development Setup
- [x] Add `dev:all` script to run both frontend (port 5173) and backend (port 3001)
- [x] Create root `package.json` with concurrently for unified startup
- [x] Update README with correct startup instructions
- [x] Test full end-to-end workflow

### Phase 6: Validation & Testing
- [x] Verify no API key input field visible in UI
- [x] Test image upload → backend analysis → results display
- [x] Verify Supabase auth works properly
- [x] Test "My Medications" functionality
- [x] Run unified `dev:all` script successfully

## Recent Updates (2025-01-16)

### Profile Page Implementation - COMPLETED
- **Branch Created**: `feature/profile-page` branch created and pushed to GitHub
- **Profile Page Added**: Complete profile page with user info, credit display, and navigation sections
- **Navigation Enhanced**: Added profile button to main camera page header
- **Platform Detection**: Implemented iOS/Android store detection for "Rate this App" feature
- **Email Integration**: Added `mailto:gladden4work@gmail.com` for Contact Us functionality

### New Features Added:
1. **User Profile Display**
   - Shows user name (from metadata or email) and email address
   - Profile picture placeholder for future implementation
   - Clean, modern card-based layout

2. **Credit Limit Card**
   - Displays current credit count (1,714)
   - Shows refresh schedule (daily at 08:00)
   - Gradient blue design matching app theme

3. **Medication Section**
   - "My Medication" button (links to existing medications page)
   - "Scan History" button (placeholder with coming soon alert)
   - Proper icons and navigation arrows

4. **Information Section**
   - "Rate this App" button with platform detection (iOS App Store/Google Play)
   - "Contact Us" button with email integration
   - Consistent styling with other sections

5. **Navigation**
   - Back button to return to main camera page
   - Profile accessible from camera page header
   - Proper page routing in switch statement

### File Changes:
- **Modified**: `src/App.jsx` - Added ProfilePage component and navigation
- **Icons Added**: Star, Mail, Pill, History, CreditCard from lucide-react

### Technical Implementation:
- Platform detection using `navigator.userAgent` for store redirects
- Email integration using `window.location.href` with mailto protocol
- Responsive design with Tailwind CSS
- Consistent with existing app color scheme and design patterns

## File Roles & Structure

### Core Files:
- `plan.md`: This document, project planning and status tracking
- `README.md`: User setup guide and project overview
- `backend/server.js`: Express server with `/analyze` endpoint, secure API key handling
- `backend/.env`: Contains `GOOGLE_API_KEY` (never commit to repo)
- `backend/package.json`: Backend dependencies and start script
- `mediscan-app/src/App.jsx`: Main React component (v2: no API key input, calls backend)
- `mediscan-app/src/supabaseClient.js`: Supabase configuration
- `mediscan-app/src/AuthContext.jsx`: Authentication context provider
- `mediscan-app/.env`: Frontend environment variables (`VITE_SUPABASE_URL`, etc.)
- `mediscan-app/package.json`: Frontend dependencies and dev script

### Folders to Remove:
- `mediscan-app/legacy-app/`: Old v1 code (duplicate, causes confusion)

## Lessons Learned During V2 Conversion
- **Hybrid Code Issues**: Having both v1 and v2 code mixed leads to confusion and bugs
- **Port Management**: Always check for port conflicts before starting services
- **API Integration**: Frontend should never directly call external APIs when backend proxy exists
- **Legacy Cleanup**: Remove old code immediately to prevent serving wrong version

## Current Goal
Replace mock image capture with real camera/file input handling for better UX and mobile support.

## Engineering Project Plan

## Notes
- Project: Medicine identification & management web app (React + Vite).
- Styling: Tailwind CSS v3; icons: `lucide-react`.
- AI: Google Gemini 2.5 Flash via a secure backend proxy.
- Core UI: Camera → Preview → Results, Profile, My Medications.
- Dev Environment: Frontend (Vite) and Backend (Express) run concurrently.

## Lessons Learned
- **Node.js Module Types**: When a Node.js backend server fails with module-related errors (`require is not defined` or `Cannot use import`), it's crucial to ensure consistency. The `backend/package.json` must include `"type": "module"` if the server code (`server.js`) uses ES Module `import` syntax. If it uses CommonJS `require()` syntax, `"type": "module"` must be removed. A mismatch between these two causes runtime errors.
- **Supabase Auth Integration**: Adding authentication with Supabase is fast, but requires careful handling of environment variables. The frontend `.env` needs the correct `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` (never commit these long-term). Sign-up flow requires email confirmation by default; users must check their inbox to activate their account. The React context/provider pattern is effective for global auth state. Always test both Google and email/password flows.
- **Monorepo/Script Management**: After flattening the repo and removing the submodule, the root `package.json` (and the `dev:all` script) was lost. Now, frontend and backend must be started in separate terminals (`npm run dev` in `mediscan-app`, `npm run start` in `backend`). If you want a single command, you must recreate a root `package.json` with a script like `concurrently`.
- **Duplicate Directories Pitfall**: Accidentally committing multiple copies of the frontend (`tmp-app/…`, `mediscan-app/legacy-app/`) can cause the dev server to serve the wrong version, leading to missing features. Always consolidate to a single source-of-truth folder and delete legacy copies immediately after migrations.

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
- [x] Create new branch `feature/initial-setup` in Med-scan-cursor repo.
- [x] Push consolidated code (including .env) to new branch `feature/auth-restoration` for portability.
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
- [x] Implement Profile page with authentication flow (sign in & sign-up).
- [ ] Persist medications list (local storage or backend).
- [ ] Add unit & E2E tests; set up CI.

## Current Goal
Replace mock image capture with real camera/file input handling for better UX and mobile support.
