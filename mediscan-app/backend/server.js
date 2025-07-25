// Simple Express backend for secure Google API key management
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import 'dotenv/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));

// Endpoint to proxy AI analysis requests
app.post('/analyze', async (req, res) => {
  const { imageBase64 } = req.body;
  const apiKey = process.env.GOOGLE_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured on server.' });
  }
  if (!imageBase64) {
    return res.status(400).json({ error: 'Missing image data.' });
  }

  try {
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
        data: imageBase64,
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
    res.status(500).json({ error: 'Failed to analyze image with Google AI.' });
  }
});

app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
