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
 * @param {boolean} props.showFailedScanQuota - Whether to show failed scan quota (only for scan_quota)
 * @param {string} props.customLabel - Optional custom label to override default feature name
 */
const QuotaDisplay = ({ 
  featureKey,
  showUpgradeButton = true,
  className = '',
  navigateTo,
  showFailedScanQuota = false,
  customLabel = null
}) => {
  const { user } = useAuth();
  const { 
    getRemainingQuota, 
    getQuotaLimit,
    getRemainingFailedScanQuota,
    getFailedScanQuotaLimit,
    currentPlan 
  } = useSubscription();
  
  const remaining = getRemainingQuota(featureKey);
  const limit = getQuotaLimit(featureKey);
  const isPremium = currentPlan?.price > 0;
  
  // Get failed scan quota if needed
  const remainingFailedScan = showFailedScanQuota ? getRemainingFailedScanQuota() : null;
  const failedScanLimit = showFailedScanQuota ? getFailedScanQuotaLimit() : null;
  
  // Get user-friendly feature name
  const getFeatureName = () => {
    switch(featureKey) {
      case 'scan_quota': return customLabel || 'Scan';
      case 'my_medication_limit': return customLabel || 'Medication';
      case 'medication_list': return customLabel || 'Medication';
      case 'followup_questions': return customLabel || 'Question';
      case 'scan_history_limit': return customLabel || 'History';
      case 'history_access': return customLabel || 'History';
      default: return customLabel || 'Feature';
    }
  };
  
  return (
    <div className={`flex flex-col ${className}`}>
      <div className="flex items-center text-sm">
        {featureKey === 'scan_history_limit' ? (
          <span>Your History limit is up to recent {limit} records</span>
        ) : (
          <span>{getFeatureName()} Limit: {remaining}/{limit}</span>
        )}
        
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
      
      {/* Show failed scan quota if requested and available */}
      {showFailedScanQuota && remainingFailedScan !== null && (
        <div className="flex items-center text-sm mt-1">
          <span className="text-gray-600">Failed Scan Quota: {remainingFailedScan}/{failedScanLimit}</span>
          <span className="ml-1 text-xs text-gray-500">(daily)</span>
        </div>
      )}
    </div>
  );
};

export default QuotaDisplay; 