// Paste this entire block into src/App.jsx

import React, { useState, useRef } from 'react';
import { supabase } from './supabaseClient.js';
import { useAuth } from './AuthContext.jsx';
import {
  Camera, Upload, Search, ArrowRight, Share2, ShoppingCart, Plus,
  Check, AlertTriangle, User, Heart, X, ChevronLeft, Info, Lock
} from 'lucide-react';

const MediScanApp = () => {
  const [currentPage, setCurrentPage] = useState('camera');
  const [capturedImage, setCapturedImage] = useState(null);
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [user, setUser] = useState(null);
  const [medications, setMedications] = useState([]);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [medicineData, setMedicineData] = useState(null);
  const fileInputRef = useRef(null);

  // Backend API URL - configurable via environment
  const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3001';

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

  const analyzeMedicine = async (imageBase64) => {
    setIsAnalyzing(true);
    setMedicineData(null);

    try {
      // Send image to backend for analysis
      const response = await fetch(`${BACKEND_URL}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          imageBase64: imageBase64,
        }),
      });

      if (!response.ok) {
        throw new Error(`Backend error: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.error) {
        throw new Error(data.error);
      }

      setMedicineData(data);
    } catch (error) {
      console.error('Medicine Analysis Error:', error);
      // Fallback to mock data for demo purposes
      setMedicineData(mockMedicineData); 
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
          onClick={() => setCurrentPage('auth')}
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

        {/* Main Camera UI */}
        <div className="flex-1 flex flex-col items-center justify-center p-6">
          {!capturedImage ? (
            <div className="w-full max-w-md">
              <div className="bg-gray-900 rounded-2xl aspect-square flex items-center justify-center mb-6">
                <div className="text-center text-gray-400">
                  <Camera size={48} className="mx-auto mb-2" />
                  <p className="text-sm">Camera preview will appear here</p>
                </div>
              </div>
              
              <div className="space-y-4">
                <button
                  onClick={handleImageCapture}
                  className="w-full bg-blue-600 text-white py-4 px-6 rounded-xl font-semibold flex items-center justify-center gap-2 hover:bg-blue-700 transition-colors"
                >
                  <Camera size={20} />
                  Take Photo
                </button>
                
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-full bg-gray-200 text-gray-800 py-4 px-6 rounded-xl font-semibold flex items-center justify-center gap-2 hover:bg-gray-300 transition-colors"
                >
                  <Upload size={20} />
                  Upload Image
                </button>
              </div>
            </div>
          ) : (
            <div className="w-full max-w-md">
              <div className="bg-white rounded-2xl p-4 mb-6">
                <img
                  src={capturedImage}
                  alt="Captured medicine"
                  className="w-full h-64 object-cover rounded-lg mb-4"
                />
                
                <div className="flex gap-3">
                  <button
                    onClick={() => setCapturedImage(null)}
                    className="flex-1 bg-gray-200 text-gray-800 py-3 px-4 rounded-lg font-medium hover:bg-gray-300 transition-colors"
                  >
                    Retake
                  </button>
                  <button
                    onClick={() => analyzeMedicine(capturedImage)}
                    disabled={isAnalyzing}
                    className="flex-1 bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                  >
                    {isAnalyzing ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
                        Analyzing...
                      </>
                    ) : (
                      <>
                        <Search size={16} />
                        Analyze
                      </>
                    )}
                  </button>
                </div>
              </div>
            </div>
          )}
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
            onClick={() => analyzeMedicine(capturedImage)}
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
            onClick={() => setCurrentPage('auth')}
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
  <div className="flex items-center gap-2 mb-1">
    <Info className="w-5 h-5 text-blue-500" />
    <h2 className="font-semibold text-lg">Description</h2>
  </div>
  <p className="text-gray-700">{medicineData.description}</p>
</div>
<hr className="my-4 border-gray-200" />
<div className="mb-4">
  <div className="flex items-center gap-2 mb-1">
    <Search className="w-5 h-5 text-green-500" />
    <h2 className="font-semibold text-lg">How It Works</h2>
  </div>
  <p className="text-gray-700">{medicineData.howItWorks}</p>
</div>
<hr className="my-4 border-gray-200" />
<div className="mb-4">
  <div className="flex items-center gap-2 mb-1">
    <Heart className="w-5 h-5 text-pink-500" />
    <h2 className="font-semibold text-lg">Dosage</h2>
  </div>
  <ul className="text-gray-700 list-none ml-0">
    <li className="flex items-center gap-2 mb-1">
      <User className="w-4 h-4 text-gray-500" />
      <span className="font-medium">Adults:</span> {medicineData.dosage.adults}
    </li>
    <li className="flex items-center gap-2 mb-1">
      <User className="w-4 h-4 text-blue-500" />
      <span className="font-medium">Teens:</span> {medicineData.dosage.teens}
    </li>
    <li className="flex items-center gap-2 mb-1">
      <User className="w-4 h-4 text-orange-500" />
      <span className="font-medium">Children:</span> {medicineData.dosage.children}
    </li>
  </ul>
</div>
<hr className="my-4 border-gray-200" />
<div className="mb-4">
  <div className="flex items-center gap-2 mb-1">
    <ArrowRight className="w-5 h-5 text-purple-500" />
    <h2 className="font-semibold text-lg">How to Take</h2>
  </div>
  <p className="text-gray-700">{medicineData.administration}</p>
</div>
<hr className="my-4 border-gray-200" />
<div className="mb-4">
  <div className="flex items-center gap-2 mb-1">
    <AlertTriangle className="w-5 h-5 text-yellow-500" />
    <h2 className="font-semibold text-lg">Precautions</h2>
  </div>
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

  // Auth Page Component
  const AuthPage = () => {
    const { user, loading } = useAuth();
    const [email, setEmail] = useState('');
    const [otp, setOtp] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [otpSent, setOtpSent] = useState(false);
    const [message, setMessage] = useState('');

    // Handle Google OAuth Sign In
    const handleGoogleSignIn = async () => {
      setSubmitting(true);
      setMessage('');
      
      try {
        const { error } = await supabase.auth.signInWithOAuth({
          provider: 'google',
          options: {
            redirectTo: window.location.origin
          }
        });
        
        if (error) throw error;
      } catch (error) {
        console.error('Google sign in error:', error);
        setMessage('Failed to sign in with Google. Please try again.');
      }
      
      setSubmitting(false);
    };

    // Handle Email OTP Request
    const handleEmailOTP = async (e) => {
      e.preventDefault();
      if (!email.trim()) return;
      
      setSubmitting(true);
      setMessage('');
      
      try {
        const { error } = await supabase.auth.signInWithOtp({
          email: email.trim(),
          options: {
            shouldCreateUser: true // This handles both signup and signin
          }
        });
        
        if (error) throw error;
        
        setOtpSent(true);
        setMessage('Check your email for the verification code!');
      } catch (error) {
        console.error('Email OTP error:', error);
        setMessage('Failed to send verification code. Please try again.');
      }
      
      setSubmitting(false);
    };

    // Handle OTP Verification
    const handleOTPVerification = async (e) => {
      e.preventDefault();
      if (!otp.trim()) return;
      
      setSubmitting(true);
      setMessage('');
      
      try {
        const { error } = await supabase.auth.verifyOtp({
          email: email.trim(),
          token: otp.trim(),
          type: 'email'
        });
        
        if (error) throw error;
        
        setMessage('Successfully signed in!');
      } catch (error) {
        console.error('OTP verification error:', error);
        setMessage('Invalid verification code. Please try again.');
      }
      
      setSubmitting(false);
    };

    if (loading) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Loading...</p>
          </div>
        </div>
      );
    }

    if (user) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg shadow-md p-6 w-full max-w-md text-center">
            <div className="mb-4">
              <User className="w-16 h-16 text-blue-600 mx-auto mb-2" />
              <h2 className="text-xl font-semibold">Welcome!</h2>
              <p className="text-gray-600 mt-2">Email: {user.email}</p>
            </div>
            <button
              className="w-full bg-red-600 text-white py-2 px-4 rounded-lg hover:bg-red-700 transition-colors"
              onClick={() => supabase.auth.signOut()}
            >
              Sign Out
            </button>
          </div>
        </div>
      );
    }

    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-lg shadow-md p-6 w-full max-w-md">
          <div className="text-center mb-6">
            <h1 className="text-2xl font-bold text-gray-900 mb-2">MediScan</h1>
            <h2 className="text-xl font-semibold mb-4">Welcome</h2>
            <p className="text-gray-600">Sign in to continue</p>
          </div>

          {message && (
            <div className={`mb-4 p-3 rounded-lg text-sm ${
              message.includes('Successfully') || message.includes('Check your email') 
                ? 'bg-green-100 text-green-700' 
                : 'bg-red-100 text-red-700'
            }`}>
              {message}
            </div>
          )}

          {/* Google Sign In Button */}
          <button
            onClick={handleGoogleSignIn}
            disabled={submitting}
            className="w-full bg-white border border-gray-300 text-gray-700 py-3 px-4 rounded-lg hover:bg-gray-50 transition-colors flex items-center justify-center mb-4 disabled:opacity-50"
          >
            <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
              <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            {submitting ? 'Signing in...' : 'Continue with Google'}
          </button>

          <div className="relative mb-4">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-300"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-2 bg-white text-gray-500">or</span>
            </div>
          </div>

          {/* Email OTP Form */}
          {!otpSent ? (
            <form onSubmit={handleEmailOTP}>
              <input
                type="email"
                placeholder="Enter your email"
                className="w-full p-3 border border-gray-300 rounded-lg mb-4 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <button
                type="submit"
                disabled={submitting || !email.trim()}
                className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
              >
                {submitting ? 'Sending...' : 'Send Verification Code'}
              </button>
            </form>
          ) : (
            <form onSubmit={handleOTPVerification}>
              <div className="mb-4">
                <p className="text-sm text-gray-600 mb-2">
                  Verification code sent to: <strong>{email}</strong>
                </p>
                <input
                  type="text"
                  placeholder="Enter 6-digit code"
                  className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  maxLength={6}
                  required
                />
              </div>
              <button
                type="submit"
                disabled={submitting || otp.length !== 6}
                className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 mb-2"
              >
                {submitting ? 'Verifying...' : 'Verify Code'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setOtpSent(false);
                  setOtp('');
                  setMessage('');
                }}
                className="w-full text-blue-600 py-2 px-4 rounded-lg hover:bg-blue-50 transition-colors"
              >
                Use Different Email
              </button>
            </form>
          )}

          <div className="mt-6 text-center text-sm text-gray-500">
            <p>
              By continuing, you agree to our Terms of Service and Privacy Policy
            </p>
          </div>
        </div>
      </div>
    );
  };

  // My Medications Page
  const MedicationsPage = () => {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="bg-white shadow-sm px-6 py-4 flex items-center justify-between">
          <button
            onClick={() => setCurrentPage('camera')}
            className="p-2 rounded-full hover:bg-gray-100 transition-colors"
          >
            <ChevronLeft size={24} />
          </button>
          <h1 className="text-xl font-semibold">My Medications</h1>
          <div className="w-10"></div>
        </div>

        <div className="p-6">
          {medications.length === 0 ? (
            <div className="text-center py-12">
              <Heart size={48} className="mx-auto text-gray-300 mb-4" />
              <p className="text-gray-500">No medications saved yet</p>
            </div>
          ) : (
            <div className="space-y-4">
              {medications.map((med) => (
                <div key={med.id} className="bg-white rounded-lg p-4 shadow-sm">
                  <h3 className="font-semibold">{med.name}</h3>
                  <p className="text-sm text-gray-600">{med.manufacturer}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    );
  };

  // Add the missing file input element before the main render logic
  return (
    <div className="App">
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        onChange={handleFileUpload}
        className="hidden"
      />
      
      {(() => {
        switch (currentPage) {
          case 'camera':
            return <CameraPage />;
          case 'preview':
            return <PreviewPage />;
          case 'results':
            return <ResultsPage />;
          case 'auth':
            return <AuthPage />;
          case 'medications':
            return <MedicationsPage />;
          default:
            return <CameraPage />;
        }
      })()}
    </div>
  );
};

export default MediScanApp;
