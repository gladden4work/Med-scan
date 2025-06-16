# MediScan v2

MediScan is a modern web application that helps users identify medicines by taking or uploading a photo. It uses AI to analyze medicine images and provides detailed information including usage instructions, precautions, and safety information.

## Features

- **Smart Medicine Recognition:** Take photos or upload images to identify medicines using Google's Generative AI
- **Passwordless Authentication:** Secure sign-in with Google OAuth or Email OTP (no passwords required)
- **Medicine Details:** Comprehensive information including name, manufacturer, usage, dosage, and precautions
- **Personal Medication Tracker:** Save and manage your medications list
- **Scan History Management:** Automatic saving and organized viewing of all medicine scans with delete functionality
- **User Profile Management:** Complete profile page with credit tracking, medication history, and app settings
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
- Supabase PostgreSQL (development database)
- Supabase Auth (Google OAuth + Email OTP)
- Base64 image storage (temporary - needs Supabase Storage bucket)

### Production Stack (Future Migration)
**Target Architecture:**
- Frontend: React + Vite → Cloudflare Pages
- Backend: Express → Cloudflare Workers
- Database: Supabase → Cloudflare D1
- Storage: Base64 → Cloudflare R2
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
Run the SQL migration to create the scan history table:

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `database/scan_history_table.sql`
4. Execute the query to create the table and set up Row Level Security

This creates a `scan_history` table with:
- User-specific scan records with RLS policies
- Automatic timestamps and UUID primary keys
- JSONB storage for complete medicine analysis data
- Optimized indexes for performance
- Cloudflare D1 compatibility for future migration

### 4. Supabase Storage Setup (Required for Image Storage)
**Current Issue**: Images are stored as base64 in the database (temporary solution)

**To enable proper image storage:**
1. Go to your Supabase project dashboard
2. Navigate to Storage
3. Create a new bucket named `scan-images`
4. Set bucket to **Public** (for image access)
5. Configure RLS policies for the bucket:
   ```sql
   -- Allow authenticated users to upload images
   CREATE POLICY "Users can upload scan images" ON storage.objects
     FOR INSERT WITH CHECK (bucket_id = 'scan-images' AND auth.uid()::text = (storage.foldername(name))[1]);
   
   -- Allow users to view their own images
   CREATE POLICY "Users can view own scan images" ON storage.objects
     FOR SELECT USING (bucket_id = 'scan-images' AND auth.uid()::text = (storage.foldername(name))[1]);
   
   -- Allow users to delete their own images
   CREATE POLICY "Users can delete own scan images" ON storage.objects
     FOR DELETE USING (bucket_id = 'scan-images' AND auth.uid()::text = (storage.foldername(name))[1]);
   ```

**Note**: The current implementation stores images as base64 in the database. This works for development but should be migrated to Supabase Storage for better performance and eventual Cloudflare R2 migration.

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
- **Authentication:** Passwordless login with Google OAuth or Email OTP

### Profile Features
- **User Information:** Display name and email with profile picture placeholder
- **Credit System:** Shows daily credit limit (1,714) with refresh schedule
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
│   │   └── supabaseClient.js # Supabase configuration
│   ├── .env.example        # Frontend environment template
│   └── package.json        # Frontend dependencies
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
1. **Database Migration**: Run `database/scan_history_table.sql` in Supabase SQL Editor
2. **Storage Bucket**: Create `scan-images` bucket in Supabase Storage
3. **Environment Variables**: Ensure all `.env` files are properly configured
4. **Google AI API**: Verify API key is working in backend

### Future (Production Migration)
1. **Cloudflare D1**: Convert Supabase tables to D1 schema
2. **Cloudflare R2**: Migrate image storage from Supabase to R2
3. **Cloudflare Workers**: Rewrite Express backend as Workers
4. **Cloudflare Pages**: Deploy frontend to Pages
