import React from 'react';
import { useAuth } from '../AuthContext';
import { useSubscription } from '../SubscriptionContext';

/**
 * Reusable component to display feature quota limits with conditional upgrade/login buttons
 * 
 * @param {Object} props
 * @param {string} props.featureKey - The feature key to display quota for (e.g., 'scan_quota')
 * @param {boolean} props.showUpgradeButton - Whether to show the upgrade button for free users
 * @param {string} props.className - Additional CSS classes
 * @param {Function} props.navigateTo - Navigation function from parent component
 */
const QuotaDisplay = ({ 
  featureKey,
  showUpgradeButton = true,
  className = '',
  navigateTo
}) => {
  const { user } = useAuth();
  const { 
    getRemainingQuota, 
    getQuotaLimit,
    currentPlan 
  } = useSubscription();
  
  const remaining = getRemainingQuota(featureKey);
  const limit = getQuotaLimit(featureKey);
  const isPremium = currentPlan?.price > 0;
  
  // Get user-friendly feature name
  const getFeatureName = () => {
    switch(featureKey) {
      case 'scan_quota': return 'Scan';
      case 'medication_list': return 'Medication';
      case 'followup_questions': return 'Question';
      case 'history_access': return 'History';
      default: return 'Feature';
    }
  };
  
  return (
    <div className={`flex items-center text-sm ${className}`}>
      <span>{getFeatureName()} Limit: {remaining}/{limit}</span>
      
      {/* Show login button for non-authenticated users who have reached their limit */}
      {!user && remaining === 0 && featureKey === 'scan_quota' && (
        <button 
          onClick={() => navigateTo('auth')}
          className="ml-2 px-3 py-1 bg-blue-500 text-white text-xs rounded-full"
        >
          Log in
        </button>
      )}
      
      {/* Show upgrade button for free authenticated users */}
      {user && !isPremium && showUpgradeButton && (
        <button 
          onClick={() => navigateTo('subscription')}
          className="ml-2 px-3 py-1 bg-indigo-500 text-white text-xs rounded-full"
        >
          Upgrade
        </button>
      )}
    </div>
  );
};

export default QuotaDisplay; 