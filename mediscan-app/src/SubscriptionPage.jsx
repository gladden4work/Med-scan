import React, { useState } from 'react';
import { useSubscription } from './SubscriptionContext';
import { useAuth } from './AuthContext';
import { ChevronLeft, CreditCard, CheckCircle, AlertCircle, Info } from 'lucide-react';

const SubscriptionPage = ({ navigateTo }) => {
  const { user } = useAuth();
  const { 
    currentPlan, 
    availablePlans, 
    loading, 
    subscribeToPlan,
    cancelSubscription
  } = useSubscription();
  
  const [processingPlan, setProcessingPlan] = useState(null);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [showConfirmCancel, setShowConfirmCancel] = useState(false);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="w-6 h-6 border-2 border-gray-300 border-t-blue-600 rounded-full animate-spin"></div>
        <span className="ml-2 text-gray-600">Loading subscription details...</span>
      </div>
    );
  }

  const handleSubscribe = async (planName) => {
    setProcessingPlan(planName);
    setError(null);
    setSuccess(null);
    
    try {
      const result = await subscribeToPlan(planName);
      
      if (result) {
        setSuccess(`Successfully subscribed to ${planName} plan!`);
      } else {
        setError('Failed to subscribe to plan. Please try again.');
      }
    } catch (error) {
      console.error('Error subscribing to plan:', error);
      setError('An error occurred while processing your subscription.');
    } finally {
      setProcessingPlan(null);
    }
  };
  
  const handleCancelSubscription = async () => {
    setProcessingPlan('cancel');
    setError(null);
    setSuccess(null);
    
    try {
      const result = await cancelSubscription(false);
      
      if (result) {
        setSuccess('Your subscription has been cancelled. You will continue to have access until the end of your billing period.');
        setShowConfirmCancel(false);
      } else {
        setError('Failed to cancel subscription. Please try again.');
      }
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      setError('An error occurred while processing your cancellation request.');
    } finally {
      setProcessingPlan(null);
    }
  };
  
  const isPlanActive = (planName) => {
    return currentPlan && currentPlan.name === planName;
  };
  
  const formatFeatures = (features) => {
    if (!features) return {};
    
    const formatted = {};
    Object.entries(features).forEach(([key, value]) => {
      formatted[key] = value;
    });
    
    return formatted;
  };
  
  const renderPlanFeatures = (plan) => {
    if (!plan || !plan.features) return null;
    
    const features = formatFeatures(plan.features);
    
    return (
      <div className="mt-4 space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-600">Scan Quota:</span>
          <span className="font-medium">
            {features.scan_quota?.value || 0} {features.scan_quota?.refresh_period === 'daily' ? 'per day' : 'per month'}
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">Follow-up Questions:</span>
          <span className="font-medium">
            {features.followup_questions?.value || 0} per day
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">History Access:</span>
          <span className="font-medium">
            {features.history_access?.value === -1 ? 'Unlimited' : features.history_access?.value || 0} scans
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">Medication List:</span>
          <span className="font-medium">
            {features.medication_list?.value === -1 ? 'Unlimited' : features.medication_list?.value || 0} items
          </span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-600">Ads:</span>
          <span className="font-medium">
            {features.ads_enabled?.value === 1 ? 'Yes' : 'No'}
          </span>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm px-6 py-4 flex items-center justify-between">
        <button
          onClick={() => navigateTo('profile')}
          className="p-2 rounded-full hover:bg-gray-100 transition-colors"
        >
          <ChevronLeft size={24} />
        </button>
        <h1 className="text-xl font-semibold">Subscription</h1>
        <div className="w-10"></div>
      </div>

      <div className="p-6 space-y-6">
        {/* Current Plan */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900">Current Plan</h2>
            <CreditCard size={24} className="text-blue-600" />
          </div>
          
          <div className="mt-4">
            <div className="flex items-center">
              <h3 className="text-xl font-bold text-gray-900">{currentPlan?.name || 'Free'}</h3>
              {currentPlan?.price > 0 && (
                <span className="ml-2 text-gray-600">${currentPlan.price}/month</span>
              )}
            </div>
            
            {currentPlan?.end_date && (
              <p className="text-sm text-gray-600 mt-1">
                Active until: {new Date(currentPlan.end_date).toLocaleDateString()}
              </p>
            )}
            
            {renderPlanFeatures(availablePlans.find(p => p.plan_name === currentPlan?.name))}
            
            {currentPlan?.price > 0 && !showConfirmCancel && (
              <button
                onClick={() => setShowConfirmCancel(true)}
                className="mt-4 w-full py-2 px-4 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
              >
                Cancel Subscription
              </button>
            )}
            
            {showConfirmCancel && (
              <div className="mt-4 p-4 bg-red-50 rounded-lg">
                <p className="text-red-700 mb-3">Are you sure you want to cancel your subscription?</p>
                <div className="flex space-x-3">
                  <button
                    onClick={handleCancelSubscription}
                    disabled={processingPlan === 'cancel'}
                    className={`flex-1 py-2 px-4 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors ${
                      processingPlan === 'cancel' ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                  >
                    {processingPlan === 'cancel' ? 'Processing...' : 'Yes, Cancel'}
                  </button>
                  <button
                    onClick={() => setShowConfirmCancel(false)}
                    className="flex-1 py-2 px-4 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
                  >
                    No, Keep
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
        
        {/* Status Messages */}
        {error && (
          <div className="bg-red-50 p-4 rounded-xl flex items-start">
            <AlertCircle size={20} className="text-red-600 mt-0.5 mr-2 flex-shrink-0" />
            <p className="text-red-700">{error}</p>
          </div>
        )}
        
        {success && (
          <div className="bg-green-50 p-4 rounded-xl flex items-start">
            <CheckCircle size={20} className="text-green-600 mt-0.5 mr-2 flex-shrink-0" />
            <p className="text-green-700">{success}</p>
          </div>
        )}
        
        {/* Available Plans */}
        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Available Plans</h2>
          
          <div className="space-y-4">
            {availablePlans
              .filter(plan => plan.plan_name !== 'Free (Not Logged In)') // Don't show the anonymous plan
              .map((plan) => (
                <div key={plan.plan_id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-gray-900">{plan.plan_name}</h3>
                    <span className="text-gray-600">${plan.price}/month</span>
                  </div>
                  
                  {renderPlanFeatures(plan)}
                  
                  <button
                    onClick={() => handleSubscribe(plan.plan_name)}
                    disabled={isPlanActive(plan.plan_name) || processingPlan === plan.plan_name}
                    className={`mt-3 w-full py-2 px-4 rounded-lg transition-colors ${
                      isPlanActive(plan.plan_name)
                        ? 'bg-green-100 text-green-700 cursor-default'
                        : processingPlan === plan.plan_name
                        ? 'bg-blue-500 text-white opacity-50 cursor-not-allowed'
                        : 'bg-blue-600 text-white hover:bg-blue-700'
                    }`}
                  >
                    {isPlanActive(plan.plan_name)
                      ? 'Current Plan'
                      : processingPlan === plan.plan_name
                      ? 'Processing...'
                      : 'Subscribe'}
                  </button>
                </div>
              ))}
          </div>
        </div>
        
        {/* Payment Information Note */}
        <div className="bg-blue-50 p-4 rounded-xl flex items-start">
          <Info size={20} className="text-blue-600 mt-0.5 mr-2 flex-shrink-0" />
          <p className="text-blue-700 text-sm">
            Payment processing will be integrated with App Store and Google Play when the mobile app is released.
            For now, this is a demonstration of the subscription interface.
          </p>
        </div>
      </div>
    </div>
  );
};

export default SubscriptionPage; 