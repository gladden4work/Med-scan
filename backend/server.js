// Simple Express backend for secure Google API key management
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));

// Endpoint to proxy AI analysis requests
app.post('/analyze', async (req, res) => {
  const { imageBase64 } = req.body;
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
If a field is not identifiable, return "Not Available".

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

    res.json(parsedData);
  } catch (error) {
    console.error('Google AI Error:', error);
    res.status(500).json({ error: 'Failed to analyze image with Google AI.', details: error.message });
  }
});

// Endpoint to handle follow-up questions about medications
app.post('/ask-follow-up', async (req, res) => {
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

    res.json({ answer });
  } catch (error) {
    console.error('Google AI Error:', error);
    res.status(500).json({ error: 'Failed to answer follow-up question.', details: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
