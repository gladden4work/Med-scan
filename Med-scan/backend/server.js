// Simple Express backend for secure Google API key management
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { createClient } from '@supabase/supabase-js';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware to check scan quota
const checkScanQuota = async (req, res, next) => {
  const { userId } = req.body;
  
  if (!userId) {
    // For anonymous users, use local session tracking
    // This would be implemented on the client side
    return next();
  }
  
  try {
    // Check if user has scan quota
    const { data: hasQuota, error: quotaError } = await supabase.rpc(
      'check_user_entitlement',
      { 
        p_user_id: userId,
        p_feature_key: 'scan_quota'
      }
    );
    
    if (quotaError) throw quotaError;
    
    if (!hasQuota) {
      return res.status(403).json({ error: 'Scan quota exceeded', code: 'QUOTA_EXCEEDED' });
    }
    
    next();
  } catch (error) {
    console.error('Error checking quota:', error);
    next(); // Proceed anyway on error to prevent blocking users
  }
};

// Middleware to check follow-up question quota
const checkFollowUpQuota = async (req, res, next) => {
  const { userId } = req.body;
  
  if (!userId) {
    // For anonymous users, use local session tracking
    return next();
  }
  
  try {
    // Check if user has follow-up question quota
    const { data: hasQuota, error: quotaError } = await supabase.rpc(
      'check_user_entitlement',
      { 
        p_user_id: userId,
        p_feature_key: 'followup_questions'
      }
    );
    
    if (quotaError) throw quotaError;
    
    if (!hasQuota) {
      return res.status(403).json({ error: 'Follow-up question quota exceeded', code: 'QUOTA_EXCEEDED' });
    }
    
    next();
  } catch (error) {
    console.error('Error checking quota:', error);
    next(); // Proceed anyway on error to prevent blocking users
  }
};

// Helper function to handle failed scans
const handleFailedScan = async (userId, result) => {
  // Check if this is a failed scan (Not Available or More than one medication)
  const isFailedScan = 
    result === "Not Available" || 
    result === "More than one medication" ||
    result === "Not a medication";
    
  if (isFailedScan && userId) {
    try {
      // Increment failed scan usage instead of regular scan quota
      await supabase.rpc(
        'increment_failed_scan_usage',
        { p_user_id: userId }
      );
      
      // Don't decrement regular scan quota for failed scans
      return true;
    } catch (error) {
      console.error('Error handling failed scan:', error);
    }
  }
  
  return false;
};

// Endpoint to proxy AI analysis requests
app.post('/analyze', checkScanQuota, async (req, res) => {
  const { imageBase64, userId } = req.body;
  const apiKey = process.env.GOOGLE_AI_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured on server.' });
  }
  if (!imageBase64) {
    return res.status(400).json({ error: 'Missing image data.' });
  }

  try {
    // Clean the base64 data (remove data:image/jpeg;base64, prefix if present)
    const cleanBase64 = imageBase64.replace(/^data:image\/[a-z]+;base64,/, '');
    
    // Initialize Google AI
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-preview-04-17' });

    const prompt = `You are an expert in pharmacology and medicine identification. Analyze the provided image of a medication.
Return a JSON object with the following structure. Do not include any other text or markdown formatting.
If a field is not identifiable, return "Not Available". If the image is not a medication, return "Not a medication". If the image contains more than than 1 medication and you can't identify which is the main medication, return "More than one medication".

{
  "name": "[Medicine Name]",
  "manufacturer": "[Manufacturer]",
  "category": "[e.g., Painkiller, Antibiotic]",
  "description": "[what is this medicine about]",
  "howItWorks": "[How it works to help patient]",
  "dosage": {
    "adults": "[The general recommended dosage for adults]",
    "teens": "[The general recommended dosage for teenagers]",
    "children": "[The general recommended dosage for children]"
  },
  "administration": "[Brief explanation of how to take it]",
  "precautions": [
    "[Usage Precaution 1]",
    "[Usage Precaution 2]",
    "[Usage Precaution 3]",
    "[...]"
  ]
}`;

    const imagePart = {
      inlineData: {
        data: cleanBase64,
        mimeType: 'image/jpeg',
      },
    };

    const result = await model.generateContent([prompt, imagePart]);
    const response = await result.response;
    const text = response.text();

    // Clean up the response which might be wrapped in markdown ```json ... ```
    const cleanedJsonString = text.replace(/```json\n?|\n?```/g, '');
    const parsedData = JSON.parse(cleanedJsonString);
    
    // Check if this is a failed scan
    const isFailedScan = await handleFailedScan(userId, parsedData.name);
    
    // If it's not a failed scan, increment regular scan quota
    if (!isFailedScan && userId) {
      await supabase.rpc(
        'increment_feature_usage',
        { 
          p_user_id: userId,
          p_feature_key: 'scan_quota'
        }
      );
    }

    res.json({
      ...parsedData,
      isFailedScan
    });
  } catch (error) {
    console.error('Google AI Error:', error);
    res.status(500).json({ error: 'Failed to analyze image with Google AI.', details: error.message });
  }
});

// Endpoint to handle follow-up questions about medications
app.post('/ask-follow-up', checkFollowUpQuota, async (req, res) => {
  const { question, medicineData, userId, scanId } = req.body;
  const apiKey = process.env.GOOGLE_AI_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured on server.' });
  }
  if (!question || !medicineData) {
    return res.status(400).json({ error: 'Missing question or medicine data.' });
  }

  try {
    // Initialize Google AI
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-preview-04-17' });

    const prompt = `You are an expert pharmacist answering questions about medications. 
A user is asking about ${medicineData.name} (${medicineData.category}) manufactured by ${medicineData.manufacturer}.

Here's what we know about this medication:
- Description: ${medicineData.description}
- How it works: ${medicineData.howItWorks}
- Administration: ${medicineData.administration}
- Dosage for adults: ${medicineData.dosage.adults}
- Dosage for teens: ${medicineData.dosage.teens}
- Dosage for children: ${medicineData.dosage.children}
- Precautions: ${medicineData.precautions.join(', ')}

The user's question is: "${question}"

Provide a clear, accurate, and helpful answer based on the information above.
If you cannot answer with certainty, explain what is known and what would require further consultation with a healthcare professional.
Keep your answer concise but thorough, focusing on factual medical information.
Do not include any markdown formatting, disclaimers, or introductory phrases like "Based on the information provided".
Just provide the direct answer to the question.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const answer = response.text();

    // Increment follow-up question usage if user is logged in
    if (userId) {
      await supabase.rpc(
        'increment_feature_usage',
        { 
          p_user_id: userId,
          p_feature_key: 'followup_questions'
        }
      );
    }

    res.json({ answer });
  } catch (error) {
    console.error('Google AI Error:', error);
    res.status(500).json({ error: 'Failed to answer follow-up question.', details: error.message });
  }
});

// Endpoint to check if user can save more medications
app.post('/check-medication-limit', async (req, res) => {
  const { userId } = req.body;
  
  if (!userId) {
    return res.status(403).json({ canSave: false, message: 'User not logged in' });
  }
  
  try {
    // Check if user can add more medications
    const { data, error } = await supabase.rpc(
      'check_medication_limit',
      { p_user_id: userId }
    );
    
    if (error) throw error;
    
    // Get current count and limit
    const { data: countData, error: countError } = await supabase.rpc(
      'get_medication_count_and_limit',
      { p_user_id: userId }
    );
    
    if (countError) throw countError;
    
    const count = countData[0]?.current_count || 0;
    const limit = countData[0]?.limit_value || 0;
    
    res.json({ 
      canSave: data, 
      currentCount: count,
      limit: limit,
      message: data ? 'User can save medication' : 'Medication limit reached'
    });
  } catch (error) {
    console.error('Error checking medication limit:', error);
    res.status(500).json({ error: 'Failed to check medication limit', details: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
