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

### Development Stack (Current)
| Area                 | Current Implementation                                |
| -------------------- | ----------------------------------------------------- |
| **Frontend**         | React (Vite)                                          |
| **Hosting**          | Local development (npm run dev:all)                  |
| **Backend API**      | Express.js + Node.js                                 |
| **Auth**             | Supabase Auth (email/social login, JWT support)      |
| **Database**         | Supabase PostgreSQL with scan_history table          |
| **Image Storage**    | Supabase Storage (scan-images bucket with RLS)       |
| **State Management** | React hooks                                           |

### Production Stack (Target - Migration Required)
| Area                 | Target Implementation                                 |
| -------------------- | ----------------------------------------------------- |
| **Frontend**         | React (Vite)                                          |
| **Hosting**          | Cloudflare Pages + Workers                            |
| **Serverless API**   | Cloudflare Workers (TypeScript)                       |
| **Auth**             | Supabase Auth → Cloudflare Access or custom JWT      |
| **Database**         | Cloudflare D1                                         |
| **Image Storage**    | Cloudflare R2                                         |
| **Budget**           | < USD 15/month                                        |
| **React State**      | Tanstack Query                                        |
| **Share links**      | Tokenized public URL, read-only DB access             |
| **Scan limits**      | User ID-based tracking                               |
| **Error logging**    | Cloudflare Logpush                                    |

### Migration Strategy
1. **Phase 1 (Current)**: Supabase for rapid development and feature completion
2. **Phase 2 (Storage)**: Add Supabase Storage bucket for images (replace base64)
3. **Phase 3 (Migration)**: Migrate to Cloudflare D1/R2 with Workers backend
4. **Phase 4 (Mobile)**: Convert to React Native with Cloudflare backend

## Recent Updates (2025-01-16)

### Profile Page Implementation - COMPLETED
- **Branch Created**: `feature/profile-page` branch created and pushed to GitHub
- **Profile Page Added**: Complete profile page with user info, credit display, and navigation sections
- **Navigation Enhanced**: Added profile button to main camera page header
- **Platform Detection**: Implemented iOS/Android store detection for "Rate this App" feature
- **Email Integration**: Added `mailto:gladden4work@gmail.com` for Contact Us functionality

### Sign-Out & Scan History Features - COMPLETED
- **Sign-Out Button**: Added secure sign-out functionality at bottom of profile page
- **Scan History Page**: Complete scan history with date grouping and delete functionality
- **Auto-Save Scans**: Successful medicine analyses automatically saved to user's scan history
- **Database Integration**: Supabase table with RLS policies for secure per-user data storage
- **Cloudflare-Ready Architecture**: Database schema and API calls designed for future Cloudflare Workers migration

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
   - "Scan History" button (now fully functional with complete page)
   - Proper icons and navigation arrows

4. **Information Section**
   - "Rate this App" button with platform detection (iOS App Store/Google Play)
   - "Contact Us" button with email integration
   - Consistent styling with other sections

5. **Sign-Out Functionality**
   - Secure sign-out button at bottom of profile page
   - Clears all user state and returns to camera page
   - Proper error handling and user feedback

6. **Scan History Management**
   - Date-grouped scan history display (e.g., "Friday, June 13")
   - Individual scan records with medicine image, name, manufacturer, and timestamp
   - Delete functionality with confirmation dialog
   - Auto-save successful scans after medicine analysis
   - Empty state with helpful messaging

7. **Navigation**
   - Back button to return to main camera page
   - Profile accessible from camera page header (merged duplicate icons)
   - Proper page routing in switch statement

### File Changes:
- **Modified**: `src/App.jsx` - Added ProfilePage component, ScanHistoryPage, sign-out logic, and scan persistence
- **Created**: `database/scan_history_table.sql` - Supabase table schema with RLS policies
- **Icons Added**: Star, Mail, Pill, History, CreditCard, LogOut, Trash2 from lucide-react

### Technical Implementation:
- **Platform Detection**: Using `navigator.userAgent` for store redirects
- **Email Integration**: Using `window.location.href` with mailto protocol
- **Database Schema**: Supabase `scan_history` table with UUID primary key, user_id foreign key, JSONB medicine data
- **Row Level Security**: RLS policies ensure users only access their own scan history
- **Auto-Save Logic**: `analyzeMedicine` function automatically saves successful scans
- **State Management**: React state for scan history with useEffect for user-based loading
- **Delete Functionality**: Confirmation dialog with optimistic UI updates
- **Date Grouping**: JavaScript date formatting and grouping for organized display
- **Responsive Design**: Tailwind CSS with consistent app color scheme
- **Cloudflare Compatibility**: Database design and API patterns ready for Cloudflare Workers migration
- **Mobile-Ready Architecture**: React components and Supabase integration suitable for React Native conversion

### Database Schema (Cloudflare-Ready):
```sql
CREATE TABLE scan_history (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  medicine_name TEXT NOT NULL,
  manufacturer TEXT,
  image_url TEXT,
  medicine_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
);
```

### Future Mobile & Cloudflare Migration Notes:
- **Supabase**: Can be replaced with Cloudflare D1 database with minimal code changes
- **React Components**: Easily convertible to React Native components
- **API Calls**: Standard fetch() calls compatible with Cloudflare Workers
- **Authentication**: Supabase Auth can be replaced with Cloudflare Access or custom JWT
- **Image Storage**: Currently uses base64, can be migrated to Cloudflare R2 storage
- **State Management**: React hooks pattern works identically in React Native

## Pending Development Tasks

### Immediate (Supabase Development)
- [x] **Supabase Storage Setup**: Create storage bucket for scan images
- [x] **Image Upload Logic**: Replace base64 with proper image uploads to Supabase Storage
- [x] **Database Migration**: Run scan_history table creation in Supabase
- [x] **Authentication Flow**: Ensure proper user session management
- [ ] **Error Handling**: Improve error states and user feedback
- [ ] **End-to-End Testing**: Verify scan history saves and displays correctly

### Future Migration (Cloudflare Production)
- [ ] **D1 Schema Design**: Convert Supabase tables to Cloudflare D1 schema
- [ ] **Workers API**: Rewrite Express backend as Cloudflare Workers
- [ ] **R2 Storage**: Migrate image storage from Supabase to Cloudflare R2
- [ ] **Authentication**: Replace Supabase Auth with Cloudflare Access or JWT
- [ ] **Frontend Updates**: Update API calls to use Workers endpoints
- [ ] **Deployment**: Set up Cloudflare Pages deployment pipeline

### Mobile Preparation
- [ ] **Component Architecture**: Ensure React components are React Native compatible
- [ ] **API Abstraction**: Create API layer that works with both web and mobile
- [ ] **State Management**: Implement proper state management for mobile
- [ ] **Image Handling**: Mobile camera integration and image processing

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
- **Supabase Storage & RLS Setup**: Implementing proper image storage requires three components: (1) Creating a public storage bucket with appropriate naming (e.g., `scan-images`), (2) Setting up Row Level Security (RLS) policies for SELECT, INSERT, and DELETE operations using `auth.uid()` and folder-based access control, and (3) Refactoring upload logic to convert base64 to blob, upload to storage, and save public URLs instead of raw image data. The filename structure `{user_id}/{timestamp}-scan.jpg` ensures user isolation and prevents conflicts. Always handle both upload and deletion of images to prevent orphaned files in storage.

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
