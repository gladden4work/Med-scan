# MediScan v2

MediScan is a modern web application that helps users identify medicines by taking or uploading a photo. It uses AI to analyze medicine images and provides detailed information including usage instructions, precautions, and safety information.

## Features

- **Smart Medicine Recognition:** Take photos or upload images to identify medicines using Google's Generative AI
- **Passwordless Authentication:** Secure sign-in with Google OAuth or Email OTP (no passwords required)
- **Medicine Details:** Comprehensive information including name, manufacturer, usage, dosage, and precautions
- **Personal Medication Tracker:** Save and manage your medications list
- **Scan History Management:** Automatic saving and organized viewing of all medicine scans with delete functionality
- **Follow-up Questions:** Ask specific questions about your medications and get AI-powered answers
- **Tiered Subscription Plans:** Free and Premium tiers with different feature entitlements
- **User Profile Management:** Complete profile page with quota tracking, medication history, and app settings
- **Secure Sign-Out:** Clean session termination with state reset
- **Platform-Aware App Rating:** Automatically detects iOS/Android and redirects to appropriate app store
- **Direct Contact Support:** Built-in email integration for user feedback and support
- **Mobile-First Design:** Responsive, modern UI built with Tailwind CSS
- **Fast & Secure:** Backend API proxy keeps your API keys safe
- **Cloudflare-Ready Architecture:** Database and API design prepared for Cloudflare Workers migration

## Tech Stack

### Development Stack (Current)
**Frontend:**
- React + Vite
- Tailwind CSS for styling
- Lucide React for icons
- Supabase for authentication

**Backend:**
- Node.js + Express
- Google Generative AI API
- CORS enabled for frontend integration

**Database & Storage:**
- Supabase PostgreSQL (with scan_history table configured)
- Supabase Auth (Google OAuth + Email OTP)
- Supabase Storage (scan-images bucket with RLS policies)

### Production Stack (Future Migration)
**Target Architecture:**
- Frontend: React + Vite → Cloudflare Pages
- Backend: Express → Cloudflare Workers
- Database: Supabase → Cloudflare D1
- Storage: Supabase Storage → Cloudflare R2
- Auth: Supabase Auth → Cloudflare Access or custom JWT

## Quick Start

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Google AI API key ([Get one here](https://aistudio.google.com/app/apikey))
- Supabase project ([Create one here](https://supabase.com))

### 1. Clone & Install
```bash
git clone https://github.com/gladden4work/Med-scan.git
cd Med-scan
npm install
```

### 2. Environment Setup
Copy the example environment files and add your credentials:

```bash
# Backend environment
cp backend/.env.example backend/.env

# Frontend environment  
cp mediscan-app/.env.example mediscan-app/.env
```

**Backend `.env` file:**
```env
GOOGLE_AI_API_KEY=your_google_ai_api_key_here
PORT=3001
```

**Frontend `.env` file:**
```env
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key_here
VITE_BACKEND_URL=http://localhost:3001
```

### 3. Database Setup (Supabase)
Run the SQL migration to create the necessary tables:

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `database/mediscan_setup.sql`
4. Execute the query to create all tables and set up Row Level Security

This creates all necessary tables with:
- User-specific scan records with RLS policies
- Automatic timestamps and UUID primary keys
- JSONB storage for complete medicine analysis data
- Optimized indexes for performance
- Tiered subscription plans and feature entitlements
- Cloudflare D1 compatibility for future migration

### 4. Supabase Storage Setup (Required for Image Storage)
**Current Status**: Supabase Storage is fully implemented with a `scan-images` bucket and RLS policies for secure image storage.

### 5. Start the Application
```bash
npm run dev:all
```

This unified command starts both:
- **Frontend:** React app on `http://localhost:5173` (or next available port)
- **Backend:** Express server on `http://localhost:3001`

### 6. Open & Use
Navigate to the frontend URL shown in your terminal and start identifying medicines!

## Authentication

MediScan v2 uses **passwordless authentication** for enhanced security:

- **Google OAuth:** One-click sign-in with your Google account
- **Email OTP:** Enter your email → receive 6-digit code → verify to sign in
- **Auto Registration:** New users are automatically registered on first OTP verification
- **No Passwords:** Enhanced security with no password storage or management

## App Navigation

### Main Pages
- **Camera Page:** Primary scanning interface with photo capture/upload
- **Preview Page:** Image confirmation before analysis
- **Results Page:** Detailed medicine information display
- **Profile Page:** User account management and app settings
- **My Medications:** Personal medication tracking and history
- **Subscription Page:** View and manage subscription plans
- **Authentication:** Passwordless login with Google OAuth or Email OTP

### Profile Features
- **User Information:** Display name and email with profile picture placeholder
- **Quota System:** Shows daily scan limits and other feature entitlements based on subscription
- **Medication Management:** 
  - Quick access to "My Medication" saved list
  - "Scan History" for viewing and managing all previous scans
- **Scan History Features:**
  - Automatic saving of successful medicine analyses
  - Date-grouped organization (e.g., "Friday, June 13")
  - Individual scan records with medicine image, name, manufacturer, and timestamp
  - Delete functionality with confirmation dialog
  - Empty state guidance for new users
- **App Information:**
  - "Rate this App" - Platform-aware store redirection
  - "Contact Us" - Direct email to gladden4work@gmail.com
- **Account Management:**
  - Secure sign-out with complete state reset

## Subscription Plans

MediScan offers three subscription tiers:

### Free (Not Logged In)
- **Scan Quota:** 3 scans per day
- **Follow-up Questions:** 1 question per day
- **History Access:** Not available
- **Medication List:** Not available

### Free (Logged In)
- **Scan Quota:** 10 scans per day
- **Follow-up Questions:** 5 questions per day
- **History Access:** 30 days
- **Medication List:** Up to 5 medications

### Premium
- **Scan Quota:** Unlimited
- **Follow-up Questions:** Unlimited
- **History Access:** Unlimited
- **Medication List:** Unlimited
- **Price:** $9.99/month

Each feature has quota tracking with appropriate reset periods (daily/monthly/none).

## Project Structure

```
Med-scan/
├── backend/                 # Node.js Express API server
│   ├── server.js           # Main server file with Google AI integration
│   ├── .env.example        # Environment template
│   └── package.json        # Backend dependencies
├── mediscan-app/           # React frontend application
│   ├── src/
│   │   ├── App.jsx         # Main app component with routing
│   │   ├── AuthContext.jsx # Supabase authentication context
│   │   ├── SubscriptionContext.jsx # Subscription management context
│   │   └── supabaseClient.js # Supabase configuration
│   ├── .env.example        # Frontend environment template
│   └── package.json        # Frontend dependencies
├── database/               # Database setup and migrations
│   ├── mediscan_setup.sql  # Consolidated database setup
│   ├── plans_schema.sql    # Subscription plans schema
│   └── user_usage_tracking.sql # Usage tracking functions
├── package.json            # Root package with unified scripts
└── README.md              # This file
```

## Development Scripts

- `npm run dev:all` - Start both frontend and backend concurrently
- `npm run dev --prefix mediscan-app` - Frontend only
- `npm run start --prefix backend` - Backend only

## Troubleshooting

**Port Conflicts:**
- If ports are in use, Vite will automatically try the next available port
- Backend runs on port 3001 by default

**Authentication Issues:**
- Ensure Supabase project has Google OAuth configured if using Google sign-in
- Check that email templates are enabled in Supabase for OTP functionality
- Verify environment variables are correctly set

**API Errors:**
- Confirm Google AI API key is valid and has proper permissions
- Check that the backend server is running and accessible

## Deployment

The application is ready for deployment to platforms like:
- **Frontend:** Vercel, Netlify, or any static hosting
- **Backend:** Railway, Render, Heroku, or any Node.js hosting

Remember to:
1. Set environment variables in your deployment platform
2. Update `VITE_BACKEND_URL` to your deployed backend URL
3. Configure Supabase redirect URLs for your domain

## Roadmap

- [ ] Add comprehensive test suite (Vitest + Playwright)
- [ ] Implement medication reminders and scheduling
- [ ] Add offline support with service workers
- [ ] Multi-language support
- [ ] Advanced medicine interaction checking
- [ ] Export medication data (PDF/CSV)

## Recent Improvements (Latest Update - June 2025)

### ✅ Improved User Experience
- **Enhanced Authentication Flow**: Main scanning functionality now accessible without login
  - Protected features (Profile, Scan History, My Medications) require login only when accessed
  - Improved login/signup experience with conditional authentication prompts
  - Better first-time user experience with direct access to core functionality

- **Advanced Navigation System**: 
  - Implemented proper page navigation with history tracking
  - Improved back button behavior for consistent user experience
  - Automatic state reset when returning to camera page from other sections

- **Interactive Scan History**:
  - Scan history items now clickable to view past scan details
  - Users can easily review previous scans with full medicine information
  - Removed redundant "Save to History" button (saves automatically)
  - Better visual feedback with cursor indicators for interactive elements

- **My Medications Feature**:
  - Grid view display of saved medications
  - Save/unsave functionality with visual feedback
  - Detailed medication view with complete information
  - Soft delete functionality (records marked as hidden rather than removed)

- **Follow-up Questions**:
  - Ask specific questions about your medications
  - Get AI-powered answers tailored to the specific medication
  - Questions and answers saved to your history
  - Intuitive interface with loading states and error handling

- **Tiered Subscription System**:
  - Three subscription plans with different feature entitlements
  - Quota tracking for scans, follow-up questions, history access, and medication lists
  - Profile page showing scan limits instead of credit limit
  - Contextual upgrade prompts when users reach quota limits
  - Graceful downgrade handling for subscriptions

### 🔧 Technical Improvements
- **Navigation Architecture**: Added `navigateTo` and `checkAuthAndNavigate` functions for better state management
- **History State Management**: Implemented tracking of previous page for improved navigation paths
- **Protected Routes Logic**: Added conditional authentication checks for profile-related features
- **Scan Details Retrieval**: New functionality to load and display previously saved scan details
- **UI Responsiveness**: Enhanced clickable areas and interactive elements for better mobile experience
- **Soft Delete Implementation**: Used PostgreSQL stored functions with `SECURITY DEFINER` privileges to handle soft deletes securely
- **Shared Components**: Extended the ResultsPage component to handle both scan history and medication details views
- **Database Optimization**: Added is_deleted flag with appropriate indexes for efficient filtering of active records
- **Subscription Management**: Implemented tiered pricing with feature entitlements and quota tracking
- **Usage Tracking**: Added PostgreSQL functions for tracking and resetting feature usage
- **Entitlement Checks**: Created middleware to verify user entitlements before actions
- **Admin Access**: Added admin_users table and RLS policies for managing admin privileges

### 🚀 Current Status
- ✅ Frontend running on http://localhost:5175/
- ✅ Backend API running on port 3001
- ✅ Non-authenticated users can access main scanning functionality
- ✅ Protected features require authentication only when accessed
- ✅ Full authentication flow (Google OAuth + Email OTP)
- ✅ Interactive scan history with clickable items
- ✅ Improved navigation with proper state management
- ✅ Profile management with secure sign-out
- ✅ My Medications with grid view and soft delete
- ✅ Shared medication and scan details view
- ✅ Follow-up questions with AI-powered answers
- ✅ Tiered subscription plans with feature entitlements
- ✅ Quota tracking for all features

## Database Structure

### Tables
- **scan_history**: Stores user scan records with soft delete capability
- **user_medications**: Stores user saved medications with soft delete capability
- **follow_up_questions**: Stores user questions about medications
- **plans**: Stores subscription plan configurations
- **plan_features**: Stores feature entitlements for each plan
- **user_plans**: Tracks user subscriptions
- **user_usage**: Tracks feature usage
- **admin_users**: Tracks users with admin privileges

### Database Functions
- **soft_delete_scan_history**: Securely handles soft deletion of scan history records
- **soft_delete_medication**: Securely handles soft deletion of medication records
- **check_user_entitlement**: Checks if a user has entitlement for a feature
- **increment_feature_usage**: Increments usage for a feature
- **get_user_quotas**: Gets all quotas for a user
- **subscribe_user_to_plan**: Subscribes a user to a plan

These functions use `SECURITY DEFINER` privileges to bypass RLS issues while maintaining proper permission checks.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ using React, Node.js, and Google AI**

## Architecture Notes

### Development vs Production
- **Current**: Using Supabase for rapid development and feature completion
- **Target**: Will migrate to Cloudflare D1 (database) + R2 (storage) + Workers (backend)
- **Migration**: All current code is designed to be easily portable to Cloudflare stack

### Why Supabase for Development?
1. **Rapid Prototyping**: Instant database setup with authentication
2. **Real-time Features**: Built-in RLS policies and real-time subscriptions
3. **Development Speed**: Faster to implement profile page and scan history
4. **Migration-Friendly**: Standard SQL and REST APIs easily portable to Cloudflare

### Migration Readiness
- Database schema uses standard SQL (D1 compatible)
- API calls use standard fetch() (Workers compatible)
- React components work identically with different backends
- Authentication can be replaced with Cloudflare Access

## Pending Setup Tasks

### Immediate (Required for Full Functionality)
1. **Database Migration**: Run `database/mediscan_setup.sql` in Supabase SQL Editor
2. **Environment Variables**: Ensure all `.env` files are properly configured
3. **Google AI API**: Verify API key is working in backend

### Future (Production Migration)
1. **Cloudflare D1**: Convert Supabase tables to D1 schema
2. **Cloudflare R2**: Migrate image storage from Supabase to R2
3. **Cloudflare Workers**: Rewrite Express backend as Workers
4. **Cloudflare Pages**: Deploy frontend to Pages
