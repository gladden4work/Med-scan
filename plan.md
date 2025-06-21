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

## Recent Updates (2025-06-18)

### Authentication Flow & Navigation Improvements - COMPLETED
- **Authentication Flow**: Changed from automatic redirect to conditional authentication for protected pages only
- **Main Page Access**: Non-authenticated users now have access to the main scanning functionality
- **Protected Features**: Profile, Scan History, and My Medications now require login when accessed
- **Navigation System**: Added proper page navigation with history tracking using `navigateTo` function
- **Back Button Handling**: Improved navigation between pages with proper state reset when returning to camera

### User Experience Enhancements - COMPLETED
- **Clickable Scan History**: Made scan history items clickable to view past scan details
- **Auto-Save Only**: Removed redundant "Save to History" button since scans are automatically saved
- **Improved Profile Access**: User icon now checks auth status before navigating to profile
- **Loading State**: Added loading spinner during authentication check
- **Consistent Navigation**: All navigation now uses consistent function calls for better state management

### Follow-up Questions Feature - COMPLETED
- **Interactive Q&A**: Added ability to ask follow-up questions about medications
- **Real-time AI Answers**: Questions are answered by the same AI model used for medication identification
- **Persistent Storage**: Questions and answers are saved to the database for logged-in users
- **User Interface**: Clean, intuitive interface with loading states and error handling
- **Contextual Answers**: AI responses are tailored to the specific medication being viewed

### My Medications Feature - IN PROGRESS
- **Grid View UI**: Updating My Medications page to display medications in a responsive grid layout
- **Supabase Integration**: Creating a user_medications table to persist saved medications
- **Save/Unsave Toggle**: Adding functionality to toggle between saving and removing medications
- **Button State**: Dynamically changing the "Add to My Medications" button to "Unsave" when a medication is already saved
- **Clickable Medication Cards**: Making medication cards clickable to view full details
- **Soft Delete**: Implementing soft delete functionality for both scan history and medications

#### Technical Implementation:
1. **Database Schema**: Created a follow_up_questions table with RLS policies
2. **Backend API**: Added a new `/ask-follow-up` endpoint to handle follow-up questions
3. **UI Component**: Implemented a question input with send button and answer display
4. **Data Persistence**: Added functionality to save questions and answers to the database
5. **Loading States**: Added visual feedback during question processing
6. **Error Handling**: Implemented graceful error handling for failed requests

### File Changes:
- **New**: `database/follow_up_questions_table.sql` - SQL schema for the follow-up questions table
- **Modified**: `backend/server.js` - Added endpoint for handling follow-up questions
- **Modified**: `src/App.jsx` - Added UI components and logic for follow-up questions
- **Modified**: `plan.md` - Updated project plan with new feature details

### Technical Implementation:
- **Question Input**: Added a form with text input and send button for follow-up questions
- **Answer Display**: Created a dedicated section to display AI-generated answers
- **API Integration**: Implemented fetch calls to the backend for question processing
- **Database Storage**: Added functions to save questions and answers to Supabase
- **User Experience**: Added loading indicators and disabled states during processing
- **Contextual Prompting**: Enhanced AI prompts with medication context for better answers

## Lessons Learned
- **Node.js Module Types**: When a Node.js backend server fails with module-related errors (`require is not defined` or `Cannot use import`), it's crucial to ensure consistency. The `backend/package.json` must include `"type": "module"` if the server code (`server.js`) uses ES Module `import` syntax. If it uses CommonJS `require()` syntax, `"type": "module"` must be removed. A mismatch between these two causes runtime errors.
- **Supabase Auth Integration**: Adding authentication with Supabase is fast, but requires careful handling of environment variables. The frontend `.env` needs the correct `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` (never commit these long-term). Sign-up flow requires email confirmation by default; users must check their inbox to activate their account. The React context/provider pattern is effective for global auth state. Always test both Google and email/password flows.
- **Monorepo/Script Management**: After flattening the repo and removing the submodule, the root `package.json` (and the `dev:all` script) was lost. Now, frontend and backend must be started in separate terminals (`npm run dev` in `mediscan-app`, `npm run start` in `backend`). If you want a single command, you must recreate a root `package.json` with a script like `concurrently`.
- **Duplicate Directories Pitfall**: Accidentally committing multiple copies of the frontend (`tmp-app/…`, `mediscan-app/legacy-app/`) can cause the dev server to serve the wrong version, leading to missing features. Always consolidate to a single source-of-truth folder and delete legacy copies immediately after migrations.
- **Supabase Storage & RLS Setup**: Implementing proper image storage requires three components: (1) Creating a public storage bucket with appropriate naming (e.g., `scan-images`), (2) Setting up Row Level Security (RLS) policies for SELECT, INSERT, and DELETE operations using `auth.uid()` and folder-based access control, and (3) Refactoring upload logic to convert base64 to blob, upload to storage, and save public URLs instead of raw image data. The filename structure `{user_id}/{timestamp}-scan.jpg` ensures user isolation and prevents conflicts. Always handle both upload and deletion of images to prevent orphaned files in storage.
- **Authentication Flow Design**: When designing authentication flows for apps with both public and protected features, it's better to conditionally prompt for authentication only when accessing protected features, rather than blocking the entire app. This provides a better user experience and allows users to explore the app's main functionality before committing to sign up.
- **Navigation State Management**: Tracking navigation history and previous pages is crucial for implementing proper "back" behavior. A robust navigation system that includes state management for both the current and previous pages creates a more natural user experience.
- **Port Conflicts During Development**: When running multiple servers locally, port conflicts can happen if a server is already running in the background. Use `EADDRINUSE` error messages to identify and resolve these conflicts by either killing the running process or configuring alternate ports.
- **RLS Policy Optimization**: When creating Row Level Security policies in Supabase, never use `auth.uid()` directly in the policy expression as it gets evaluated separately for each row during queries. Instead, use the subquery pattern `user_id IN (SELECT auth.uid())` which evaluates the function only once per query. This optimization is critical for maintaining performance as tables grow. The pattern should be used for all policy types (SELECT, INSERT, UPDATE, DELETE). Always remember to structure RLS policies for scalability from the beginning since they're hard to diagnose later.
- **Component Reusability**: When designing UI components, always prioritize reusability and extensibility. Building components that can be adapted to multiple use cases (e.g., a shared results page for both scan history and medications) simplifies maintenance and ensures consistent UX.
- **Soft Delete Strategy**: Implementing soft deletes (marking records as deleted rather than removing them) provides data recovery options and audit trails. Using an is_deleted flag and filtering queries is a simple approach that works well for most use cases, but also requires monitoring for database growth over time.
- **RLS vs. Stored Functions**: When implementing data operations requiring specific security checks, PostgreSQL stored functions with `SECURITY DEFINER` are more reliable than Row Level Security (RLS) policies. While RLS is simpler to implement, it can become complex when handling UPDATE operations. Stored functions centralize security logic server-side, bypass RLS issues, and provide cleaner client code by reducing the need for multi-step operations (verify ownership, then update).
- **SQL Migration Consolidation**: When working with multiple SQL migration files that build upon each other, it's valuable to periodically consolidate them into a single comprehensive setup file. This approach simplifies onboarding for new developers, reduces the chance of migration errors, and provides a clear snapshot of the current database schema. By organizing the consolidated file into logical sections (tables, indexes, RLS policies, functions, etc.), it becomes both a setup script and documentation of the database structure.
- **AI Context Enhancement**: When designing prompts for AI models, providing rich context about the specific domain (like medication details) significantly improves the quality and relevance of responses. Structuring prompts with clear instructions and comprehensive background information helps the AI generate more accurate and helpful answers.
- **Form Submission UX**: For interactive features like follow-up questions, it's important to provide immediate visual feedback (loading indicators, disabled inputs) during processing to improve user experience. This prevents multiple submissions and reduces user confusion about whether their action was registered.

## Pending Development Tasks

### Immediate (Supabase Development)
- [x] **Supabase Storage Setup**: Create storage bucket for scan images
- [x] **Image Upload Logic**: Replace base64 with proper image uploads to Supabase Storage
- [x] **Database Migration**: Run scan_history table creation in Supabase
- [x] **Authentication Flow**: Ensure proper user session management
- [x] **Navigation Improvements**: Implement proper navigation and back button handling
- [x] **Clickable Scan History**: Make scan history items clickable to view past scan details
- [x] **My Medications Feature**: Implement grid view UI and save/unsave functionality
- [x] **Medication Details View**: Make medication cards clickable to view full details
- [x] **Soft Delete Implementation**: Add soft delete functionality to both scan history and medications
- [x] **Follow-up Questions Feature**: Add ability to ask follow-up questions about medications
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
Implement medication details view and soft delete functionality for both scan history and medications.

## Engineering Project Plan

## Notes
- Project: Medicine identification & management web app (React + Vite).
- Styling: Tailwind CSS v3; icons: `lucide-react`.
- AI: Google Gemini 2.5 Flash via a secure backend proxy.
- Core UI: Camera → Preview → Results, Profile, My Medications.
- Dev Environment: Frontend (Vite) and Backend (Express) run concurrently.

## File Roles
- `plan.md`: This document, outlining project goals and tasks.
- `backend/server.js`: The Express backend server that proxies requests to the Google AI API, keeping the API key secure.
- `backend/.env`: Stores the secret `GOOGLE_API_KEY`.
- `backend/package.json`: Manages backend dependencies and scripts.
- `mediscan-app/src/App.jsx`: The main React component for the frontend UI and logic.
- `mediscan-app/package.json`: Manages frontend dependencies and scripts, including the `dev:all` script to run both servers.
- `.gitignore`: Specifies which files and folders Git should ignore, preventing secrets and unnecessary files from being committed.
- `database/scan_history_table.sql`: SQL schema for the scan history table.
- `database/user_medications_table.sql`: SQL schema for the user medications table.
- `database/soft_delete_migration.sql`: SQL migration for adding soft delete functionality.
- `database/soft_delete_functions.sql`: SQL functions for securely implementing soft delete operations.

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
- [x] Implement My Medications page with grid view and save/unsave functionality.
- [x] Implement clickable medication cards and shared details view.
- [x] Add soft delete functionality to both scan history and medications.
- [ ] Persist medications list using Supabase.
- [ ] Add unit & E2E tests; set up CI.

## Current Goal
Implement medication details view and soft delete functionality for both scan history and medications.
