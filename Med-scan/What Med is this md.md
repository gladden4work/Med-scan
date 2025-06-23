# What Med is this

1. Concept
    - Initial draft - Done
        
        Create a mobile app that allow user to search medicine, supplements and medical equipment based on image (camera or upload an image)
        
        - page 1, camera, allow user to take photo of the medicine or upload a photo with medicine. Let user preview the photo before sending.
        - Page 2, show the picture of the medicine then followed by the name and manufacturer and the catoroies (status design. Categories: Medicine, supplements or medical equipment). Present the information of the med in the following way, what is this for, How does it work, Does and use (18+ how much, 12~17 how much, children how much. Eat or drink), Precautions.
        - The end of page 2 is actions item: Im taking this, Share or Where to buy.
        - if user does not update a medicine, supplements or medical equipment, tell user that No supplement, medicine or medical equipment found. User can click report issue to report.
        - If user can log in via google or email.
        - if user click I'm taking this, save this medicine to My Medication. My Medication is a list of medication that user is taking. They can add or remove, User can also categorize the med to taking daily/weekly/monthly, only when needed, and no longer taking.
        - if user click Share, generate a sharable link. If another user clicks the link, there will be nevigated to a webpage showing medical information like page 2.
        - If user click where to buy, lead them to external link to buy
2. Requirement + UI 
    - App page - Mobile app, android and IOS
        - Camera page
        - Preview page
        - Detailed page
        - Saved med page
        - Shared page
    - Backend control page - Admin page, web app
        - Check request
        - Switch default AI engine (Perplexity/Gemini with Google grounding )
        - See Feedback that customer give in App page
        - New sign up log - New sign up details app page
    - Optimization
        - Rule for saving the med to info (Dont requery)
            - Phash similarity from backend, but return the uploaded images 
        - This is not a med page
    - Monetization
        - IAP. Limit 10 total
            - Ask follow up question.
        - Where to buy
            - Search near by, click the first link, attach UTM
        - Potentially ads


Infrastructure

| Area                 | Decision                                              |
| -------------------- | ----------------------------------------------------- |
| **Frontend**         | React (Vite or CRA)                                   |
| **Hosting**          | Cloudflare Pages (for React) + Workers (for API)      |
| **Serverless API**   | Cloudflare Workers (TypeScript)                       |
| **Auth**             | Supabase Auth (email/social login, JWT support)       |
| **Budget**           | < USD 15/month                                        |
| **Image processing** | Python (for perceptual hash), likely compiled to WASM |
| **Object storage**   | Cloudflare R2 (for uploaded med images)               |
| **Database (for metadata, user records)**         | cloudflare d1              |
| **State management in React** | Tanstack Query              |
| **Share link behavior** | Use tokenized public URL + read-only DB access| 
| **Scan limits per user/IP** |  Supabase user ID |
| **Error logging** | Cloudflare Logpush |

