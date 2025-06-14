// Paste this entire block into src/App.jsx

import React, { useState, useRef } from 'react';
import {
  Camera, Upload, Search, ArrowRight, Share2, ShoppingCart, Plus,
  Check, AlertTriangle, User, Heart, X, ChevronLeft, Info, Lock
} from 'lucide-react';
import { GoogleGenerativeAI } from '@google/generative-ai';

const MediScanApp = () => {
  const [currentPage, setCurrentPage] = useState('camera');
  const [capturedImage, setCapturedImage] = useState(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState(null);
  const [medications, setMedications] = useState([]);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [medicineData, setMedicineData] = useState(null);
  const [apiKey, setApiKey] = useState('');
  const fileInputRef = useRef(null);

  // Mock medicine data
  const mockMedicineData = {
    name: "Paracetamol 500mg",
    manufacturer: "Johnson & Johnson",
    category: "Medicine",
    image: "/api/placeholder/300/200",
    description: "Pain relief and fever reducer commonly used for headaches, muscle aches, and reducing fever.",
    howItWorks: "Paracetamol works by blocking the production of prostaglandins in the brain that cause pain and fever.",
    dosage: {
      adults: "500-1000mg every 4-6 hours (max 4000mg daily)",
      teens: "500mg every 4-6 hours (max 3000mg daily)",
      children: "10-15mg per kg body weight every 4-6 hours"
    },
    administration: "Take with water, can be taken with or without food",
    precautions: [
      "Do not exceed recommended dose",
      "Avoid alcohol while taking this medication",
      "Consult doctor if symptoms persist beyond 3 days",
      "Not suitable for people with liver problems"
    ]
  };

  const handleImageCapture = () => {
    // On mobile, this could trigger the camera. For desktop, we'll open the file selector.
    fileInputRef.current?.click();
  };

  const handleFileUpload = (event) => {
    const file = event.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        setCapturedImage(e.target.result);
        setCurrentPage('preview');
      };
      reader.readAsDataURL(file);
    }
  };

    const analyzeMedicine = async () => {
    if (!apiKey) {
      alert('Please enter your Google AI API key first.');
      return;
    }

    setIsAnalyzing(true);
    setCurrentPage('results');

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash-preview-04-17',
        tools: [{googleSearchRetrieval: {}}],
      });

      const imagePart = {
        inlineData: {
          data: capturedImage.split(',')[1], // Base64-encoded image data
          mimeType: 'image/jpeg',
        },
      };

      const prompt = `
        You are an expert in pharmacology and medicine identification. Analyze the provided image of a medication.
        Return a JSON object with the following structure. Do not include any other text or markdown formatting.
        If a field is not identifiable, return "Not Available".

        {
          "name": "[Medicine Name]",
          "manufacturer": "[Manufacturer]",
          "category": "[e.g., Painkiller, Antibiotic]",
          "description": "[Brief description]",
          "howItWorks": "[How it works]",
          "dosage": {
            "adults": "[Adult dosage]",
            "teens": "[Teenage dosage]",
            "children": "[Children dosage]"
          },
          "administration": "[How to take it]",
          "precautions": [
            "[Precaution 1]",
            "[Precaution 2]"
          ]
        }
      `;

      const result = await model.generateContent([prompt, imagePart]);
      const response = await result.response;
      const text = response.text();
      
      // Clean the response to get only the JSON part
      const jsonText = text.replace(/```json|```/g, '').trim();
      const parsedData = JSON.parse(jsonText);

      setMedicineData(parsedData);
    } catch (error) {
      console.error('AI Analysis Error:', error);
      // Fallback to a generic error message or mock data
      setMedicineData(null); 
    }

    setIsAnalyzing(false);
  };

  const handleAddToMedications = () => {
    const newMed = {
      ...medicineData,
      id: Date.now(),
      frequency: 'daily',
      addedDate: new Date().toISOString()
    };
    setMedications([...medications, newMed]);
  };

  const generateShareLink = () => {
    const shareUrl = `https://mediscan.app/medicine/${medicineData.name.replace(/\s+/g, '-').toLowerCase()}`;
    navigator.clipboard.writeText(shareUrl);
    alert('Share link copied to clipboard!');
  };

  // Camera Page Component
  const CameraPage = () => (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm px-6 py-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">MediScan</h1>
        <button
          onClick={() => setCurrentPage('profile')}
          className="p-2 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors"
        >
          <User className="w-5 h-5 text-gray-600" />
        </button>
      </div>

      {/* Main Content */}
      <div className="px-6 py-8">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold text-gray-900 mb-3">
            Identify Your Medicine
          </h2>
          <p className="text-gray-600 text-lg">
            Take a photo or upload an image to get detailed information
          </p>
        </div>

        {/* Camera Preview */}
        <div className="mb-8">
          <div className="relative bg-gray-900 rounded-3xl overflow-hidden aspect-[4/3] mb-6">
            <div className="flex items-center justify-center h-full">
              <div className="text-center text-white">
                <Camera className="w-16 h-16 mx-auto mb-4 opacity-50" />
                <p className="text-gray-300">Camera preview will appear here</p>
              </div>
            </div>

            {/* Camera overlay */}
            <div className="absolute inset-0 pointer-events-none">
              <div className="absolute inset-4 border-2 border-white rounded-2xl opacity-30"></div>
              <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <div className="w-8 h-8 border-2 border-white rounded-full"></div>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-4">
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="password"
                  value={apiKey}
                  onChange={(e) => setApiKey(e.target.value)}
                  placeholder="Enter Google AI API Key"
                  className="w-full bg-white border-2 border-gray-200 rounded-2xl py-4 pl-12 pr-4 text-gray-800 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            <button
              onClick={handleImageCapture}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-4 px-6 rounded-2xl flex items-center justify-center space-x-3 transition-all transform hover:scale-[1.02]"
            >
              <Camera className="w-6 h-6" />
              <span>Take Photo</span>
            </button>

            <button
              onClick={() => fileInputRef.current?.click()}
              className="w-full bg-white border-2 border-gray-200 hover:border-gray-300 text-gray-700 font-semibold py-4 px-6 rounded-2xl flex items-center justify-center space-x-3 transition-all hover:bg-gray-50"
            >
              <Upload className="w-6 h-6" />
              <span>Upload Image</span>
            </button>

            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleFileUpload}
              className="hidden"
            />
          </div>
        </div>
      </div>
    </div>
  );

  // New Preview Page Component
  const PreviewPage = () => (
    <div className="min-h-screen bg-gray-900 flex flex-col text-white">
      {/* Image Preview */}
      <div className="flex-1 flex items-center justify-center p-4 overflow-hidden">
        {capturedImage && (
          <img
            src={capturedImage}
            alt="Medicine preview"
            className="max-w-full max-h-full object-contain rounded-2xl"
          />
        )}
      </div>

      {/* Action Buttons */}
      <div className="p-6 bg-black/30 backdrop-blur-sm">
        <div className="text-center mb-5">
            <h3 className="font-semibold text-lg">Confirm Photo</h3>
            <p className="text-white/70 text-sm">Is the image clear enough to analyze?</p>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <button
            onClick={() => {
              setCapturedImage(null);
              setCurrentPage('camera');
            }}
            className="w-full bg-white/20 hover:bg-white/30 text-white font-semibold py-4 px-6 rounded-2xl flex items-center justify-center space-x-2 transition-colors"
          >
            <X className="w-5 h-5" />
            <span>Take Another</span>
          </button>
          <button
            onClick={analyzeMedicine}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-4 px-6 rounded-2xl flex items-center justify-center space-x-2 transition-colors"
          >
            <Check className="w-5 h-5" />
            <span>Continue</span>
          </button>
        </div>
      </div>
    </div>
  );

  // Results Page Component
  const ResultsPage = () => {
    if (isAnalyzing) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center mx-auto mb-4 animate-pulse">
              <Search className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">Analyzing your image...</h2>
            <p className="text-gray-600">This may take a few seconds</p>
          </div>
        </div>
      );
    }

    if (!medicineData) {
      return (
        <div className="min-h-screen bg-gray-50">
          <div className="px-6 py-8">
            <button
              onClick={() => setCurrentPage('camera')}
              className="flex items-center space-x-2 text-gray-600 mb-6"
            >
              <ChevronLeft className="w-5 h-5" />
              <span>Back to camera</span>
            </button>

            <div className="text-center py-16">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <AlertTriangle className="w-8 h-8 text-red-600" />
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                No medicine found
              </h2>
              <p className="text-gray-600 mb-6">
                We couldn't identify the item in your image. Please try again with a clearer photo.
              </p>
              <button className="bg-red-600 hover:bg-red-700 text-white font-semibold py-3 px-6 rounded-xl">
                Report Issue
              </button>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className="min-h-screen bg-gray-50">
        <div className="bg-white shadow-sm px-6 py-4 flex items-center justify-between">
          <button
            onClick={() => setCurrentPage('camera')}
            className="flex items-center space-x-2 text-gray-600"
          >
            <ChevronLeft className="w-5 h-5" />
            <span>Back</span>
          </button>
          <button
            onClick={() => setCurrentPage('profile')}
            className="p-2 rounded-full bg-gray-100"
          >
            <User className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        <div className="px-6 py-6">
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm mb-6">
            <img
              src={capturedImage}
              alt={medicineData.name}
              className="w-full h-64 object-cover"
            />
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm mb-6">
  <h1 className="text-2xl font-bold text-gray-900 mb-1">{medicineData.name}</h1>
  <p className="text-gray-600 mb-2">{medicineData.manufacturer}</p>
  <div className="mb-4">
    <span className="inline-block bg-blue-100 text-blue-800 text-xs px-3 py-1 rounded-full font-semibold">{medicineData.category}</span>
  </div>
  <div className="mb-4">
    <h2 className="font-semibold text-lg mb-1">Description</h2>
    <p className="text-gray-700">{medicineData.description}</p>
  </div>
  <div className="mb-4">
    <h2 className="font-semibold text-lg mb-1">How It Works</h2>
    <p className="text-gray-700">{medicineData.howItWorks}</p>
  </div>
  <div className="mb-4">
    <h2 className="font-semibold text-lg mb-1">Dosage</h2>
    <ul className="text-gray-700 list-disc list-inside">
      <li><span className="font-medium">Adults:</span> {medicineData.dosage.adults}</li>
      <li><span className="font-medium">Teens:</span> {medicineData.dosage.teens}</li>
      <li><span className="font-medium">Children:</span> {medicineData.dosage.children}</li>
    </ul>
  </div>
  <div className="mb-4">
    <h2 className="font-semibold text-lg mb-1">How to Take</h2>
    <p className="text-gray-700">{medicineData.administration}</p>
  </div>
  <div className="mb-4">
    <h2 className="font-semibold text-lg mb-1">Precautions</h2>
    <ul className="text-gray-700 list-disc list-inside">
      {medicineData.precautions.map((prec, idx) => (
        <li key={idx}>{prec}</li>
      ))}
    </ul>
  </div>
  <div className="flex gap-4 mt-6">
    <button
      onClick={handleAddToMedications}
      className="flex-1 bg-green-600 hover:bg-green-700 text-white font-semibold py-3 px-6 rounded-xl flex items-center justify-center space-x-2 transition-colors"
    >
      <Plus className="w-5 h-5" />
      <span>Add to My Medications</span>
    </button>
    <button
      onClick={generateShareLink}
      className="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-xl flex items-center justify-center space-x-2 transition-colors"
    >
      <Share2 className="w-5 h-5" />
      <span>Share</span>
    </button>
  </div>
</div>
        </div>
      </div>
    );
  };

  // Profile/Login Page
  const ProfilePage = () => { /* ... ProfilePage code ... */ return <div>Profile Page</div> };

  // My Medications Page
  const MedicationsPage = () => { /* ... MedicationsPage code ... */ return <div>Medications Page</div>};

  // Main render logic
  switch (currentPage) {
    case 'camera':
      return <CameraPage />;
    case 'preview':
      return <PreviewPage />;
    case 'results':
      return <ResultsPage />;
    case 'profile':
      return <ProfilePage />;
    case 'medications':
      return <MedicationsPage />;
    default:
      return <CameraPage />;
  }
};

export default MediScanApp;
