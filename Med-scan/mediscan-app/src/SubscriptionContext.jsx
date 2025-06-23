import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from './supabaseClient';
import { useAuth } from './AuthContext';

// Create context
const SubscriptionContext = createContext(null);

// Default entitlements for non-logged in users
const DEFAULT_ANONYMOUS_ENTITLEMENTS = {
  scan_quota: { limit: 3, used: 0, refresh: 'daily' },
  failed_scan_limit_daily: { limit: 2, used: 0, refresh: 'daily' },
  followup_questions: { limit: 0, used: 0, refresh: 'daily' },
  history_access: { limit: 0, used: 0, refresh: null },
  scan_history_limit: { limit: 0, used: 0, refresh: null },
  medication_list: { limit: 0, used: 0, refresh: null },
  my_medication_limit: { limit: 0, used: 0, refresh: null },
  ads_enabled: { value: 1, refresh: null }
};

// Default entitlements for logged in users with no subscription
const DEFAULT_FREE_ENTITLEMENTS = {
  scan_quota: { limit: 5, used: 0, refresh: 'daily' },
  failed_scan_limit_daily: { limit: 3, used: 0, refresh: 'daily' },
  followup_questions: { limit: 3, used: 0, refresh: 'daily' },
  history_access: { limit: 3, used: 0, refresh: null },
  scan_history_limit: { limit: 3, used: 0, refresh: null },
  medication_list: { limit: 3, used: 0, refresh: null },
  my_medication_limit: { limit: 3, used: 0, refresh: null },
  ads_enabled: { value: 1, refresh: null }
};

export const SubscriptionProvider = ({ children }) => {
  const { user } = useAuth();
  const [currentPlan, setCurrentPlan] = useState(null);
  const [entitlements, setEntitlements] = useState(DEFAULT_ANONYMOUS_ENTITLEMENTS);
  const [availablePlans, setAvailablePlans] = useState([]);
  const [loading, setLoading] = useState(true);

  // Load user's subscription and entitlements
  useEffect(() => {
    const loadUserSubscription = async () => {
      setLoading(true);
      
      try {
        if (!user) {
          // Not logged in, use anonymous entitlements
          setCurrentPlan({ name: 'Free (Not Logged In)', price: 0 });
          setEntitlements(DEFAULT_ANONYMOUS_ENTITLEMENTS);
        } else {
          // Fetch user's plan and entitlements from database
          const { data: quotaData, error: quotaError } = await supabase.rpc(
            'get_user_quotas',
            { p_user_id: user.id }
          );
          
          if (quotaError) throw quotaError;
          
          // Get user's plan info
          const { data: planData, error: planError } = await supabase.rpc(
            'get_user_plan_info',
            { p_user_id: user.id }
          );
          
          if (planError) throw planError;
          
          // Format the entitlements
          if (quotaData && quotaData.length > 0) {
            const formattedEntitlements = {};
            
            quotaData.forEach(item => {
              formattedEntitlements[item.feature_key] = {
                limit: item.limit_value,
                used: item.current_usage,
                refresh: item.refresh_period
              };
            });
            
            setEntitlements(formattedEntitlements);
          } else {
            // Use default free entitlements if no data found
            setEntitlements(DEFAULT_FREE_ENTITLEMENTS);
          }
          
          // Set current plan
          if (planData && planData.length > 0) {
            setCurrentPlan(planData[0]);
          } else {
            setCurrentPlan({ name: 'Free (Logged In)', price: 0 });
          }
        }
        
        // Load available plans
        await loadAvailablePlans();
        
      } catch (error) {
        console.error('Error loading subscription data:', error);
        // Fallback to appropriate default entitlements
        setEntitlements(user ? DEFAULT_FREE_ENTITLEMENTS : DEFAULT_ANONYMOUS_ENTITLEMENTS);
        setCurrentPlan({ 
          name: user ? 'Free (Logged In)' : 'Free (Not Logged In)', 
          price: 0 
        });
      } finally {
        setLoading(false);
      }
    };
    
    loadUserSubscription();
  }, [user]);
  
  // Load available subscription plans
  const loadAvailablePlans = async () => {
    try {
      const { data, error } = await supabase.rpc('get_available_plans');
      
      if (error) throw error;
      
      if (data) {
        setAvailablePlans(data);
      }
    } catch (error) {
      console.error('Error loading available plans:', error);
    }
  };
  
  // Check if user has entitlement for a feature
  const checkEntitlement = async (featureKey) => {
    // For anonymous users or during loading, use the state data
    if (!user || loading) {
      const feature = entitlements[featureKey];
      if (!feature) return false;
      
      // If limit is 0, no entitlement
      if (feature.limit === 0) return false;
      
      // If used < limit, has entitlement
      return feature.used < feature.limit;
    }
    
    // For logged in users, check with the database for the most current data
    try {
      const { data, error } = await supabase.rpc(
        'check_user_entitlement',
        { 
          p_user_id: user.id,
          p_feature_key: featureKey
        }
      );
      
      if (error) throw error;
      
      return data;
    } catch (error) {
      console.error(`Error checking entitlement for ${featureKey}:`, error);
      
      // Fallback to state data if database check fails
      const feature = entitlements[featureKey];
      if (!feature) return false;
      return feature.used < feature.limit;
    }
  };
  
  // Check if user can save more medications
  const checkMedicationLimit = async () => {
    if (!user) return false;
    
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/check-medication-limit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: user.id }),
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      return data.canSave;
    } catch (error) {
      console.error('Error checking medication limit:', error);
      
      // Fallback to entitlement check
      return checkEntitlement('my_medication_limit');
    }
  };
  
  // Get medication count and limit
  const getMedicationCountAndLimit = async () => {
    if (!user) {
      return { currentCount: 0, limit: 0 };
    }
    
    try {
      const response = await fetch(`${import.meta.env.VITE_API_URL}/check-medication-limit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: user.id }),
      });
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      return {
        currentCount: data.currentCount,
        limit: data.limit
      };
    } catch (error) {
      console.error('Error getting medication count and limit:', error);
      
      // Fallback to state data
      const feature = entitlements['my_medication_limit'];
      return {
        currentCount: feature ? feature.used : 0,
        limit: feature ? feature.limit : 0
      };
    }
  };
  
  // Increment usage for a feature
  const incrementUsage = async (featureKey) => {
    // For anonymous users, just update the state
    if (!user) {
      setEntitlements(prev => {
        const feature = prev[featureKey];
        if (!feature) return prev;
        
        return {
          ...prev,
          [featureKey]: {
            ...feature,
            used: feature.used + 1
          }
        };
      });
      
      return true;
    }
    
    // For logged in users, update the database
    try {
      const { data, error } = await supabase.rpc(
        'increment_feature_usage',
        { 
          p_user_id: user.id,
          p_feature_key: featureKey
        }
      );
      
      if (error) throw error;
      
      // Also update local state
      setEntitlements(prev => {
        const feature = prev[featureKey];
        if (!feature) return prev;
        
        return {
          ...prev,
          [featureKey]: {
            ...feature,
            used: feature.used + 1
          }
        };
      });
      
      return data;
    } catch (error) {
      console.error(`Error incrementing usage for ${featureKey}:`, error);
      return false;
    }
  };
  
  // Increment failed scan usage
  const incrementFailedScanUsage = async () => {
    // For anonymous users, just update the state
    if (!user) {
      setEntitlements(prev => {
        const feature = prev['failed_scan_limit_daily'];
        if (!feature) return prev;
        
        return {
          ...prev,
          'failed_scan_limit_daily': {
            ...feature,
            used: feature.used + 1
          }
        };
      });
      
      return true;
    }
    
    // For logged in users, update the database
    try {
      const { data, error } = await supabase.rpc(
        'increment_failed_scan_usage',
        { p_user_id: user.id }
      );
      
      if (error) throw error;
      
      // Also update local state
      setEntitlements(prev => {
        const feature = prev['failed_scan_limit_daily'];
        if (!feature) return prev;
        
        return {
          ...prev,
          'failed_scan_limit_daily': {
            ...feature,
            used: feature.used + 1
          }
        };
      });
      
      return data;
    } catch (error) {
      console.error('Error incrementing failed scan usage:', error);
      return false;
    }
  };
  
  // Subscribe to a plan
  const subscribeToPlan = async (planName) => {
    if (!user) return false;
    
    try {
      const { data, error } = await supabase.rpc(
        'subscribe_user_to_plan',
        { 
          p_user_id: user.id,
          p_plan_name: planName
        }
      );
      
      if (error) throw error;
      
      // Reload subscription data
      const { data: planData, error: planError } = await supabase.rpc(
        'get_user_plan_info',
        { p_user_id: user.id }
      );
      
      if (planError) throw planError;
      
      if (planData && planData.length > 0) {
        setCurrentPlan(planData[0]);
      }
      
      // Reload entitlements
      const { data: quotaData, error: quotaError } = await supabase.rpc(
        'get_user_quotas',
        { p_user_id: user.id }
      );
      
      if (quotaError) throw quotaError;
      
      if (quotaData && quotaData.length > 0) {
        const formattedEntitlements = {};
        
        quotaData.forEach(item => {
          formattedEntitlements[item.feature_key] = {
            limit: item.limit_value,
            used: item.current_usage,
            refresh: item.refresh_period
          };
        });
        
        setEntitlements(formattedEntitlements);
      }
      
      return true;
    } catch (error) {
      console.error('Error subscribing to plan:', error);
      return false;
    }
  };
  
  // Cancel subscription
  const cancelSubscription = async (immediate = false) => {
    if (!user) return false;
    
    try {
      const { data, error } = await supabase.rpc(
        'cancel_user_subscription',
        { 
          p_user_id: user.id,
          p_immediate: immediate
        }
      );
      
      if (error) throw error;
      
      // Reload subscription data if immediate cancellation
      if (immediate) {
        const { data: planData, error: planError } = await supabase.rpc(
          'get_user_plan_info',
          { p_user_id: user.id }
        );
        
        if (planError) throw planError;
        
        if (planData && planData.length > 0) {
          setCurrentPlan(planData[0]);
        } else {
          setCurrentPlan({ name: 'Free (Logged In)', price: 0 });
        }
      }
      
      return data;
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      return false;
    }
  };
  
  // Format quota display
  const formatQuotaDisplay = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature) return '0/0';
    
    return `${Math.max(0, feature.limit - feature.used)}/${feature.limit}`;
  };
  
  // Get remaining quota
  const getRemainingQuota = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature) return 0;
    
    return Math.max(0, feature.limit - feature.used);
  };
  
  // Get quota limit
  const getQuotaLimit = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature) return 0;
    
    return feature.limit;
  };
  
  // Get remaining failed scan quota
  const getRemainingFailedScanQuota = () => {
    const feature = entitlements['failed_scan_limit_daily'];
    if (!feature) return 0;
    
    return Math.max(0, feature.limit - feature.used);
  };
  
  // Get failed scan quota limit
  const getFailedScanQuotaLimit = () => {
    const feature = entitlements['failed_scan_limit_daily'];
    if (!feature) return 0;
    
    return feature.limit;
  };
  
  // Should show ads
  const shouldShowAds = () => {
    const feature = entitlements['ads_enabled'];
    if (!feature) return true;
    
    return feature.value > 0;
  };
  
  // Get refresh period text
  const getRefreshPeriodText = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature) return '';
    
    switch (feature.refresh) {
      case 'daily':
        return 'Resets daily';
      case 'monthly':
        return 'Resets monthly';
      case null:
      case 'none':
        return 'No reset';
      default:
        return `Resets ${feature.refresh}`;
    }
  };
  
  // Context value
  const value = {
    currentPlan,
    entitlements,
    availablePlans,
    loading,
    checkEntitlement,
    incrementUsage,
    incrementFailedScanUsage,
    checkMedicationLimit,
    getMedicationCountAndLimit,
    formatQuotaDisplay,
    getRemainingQuota,
    getQuotaLimit,
    getRemainingFailedScanQuota,
    getFailedScanQuotaLimit,
    shouldShowAds,
    getRefreshPeriodText,
    subscribeToPlan,
    cancelSubscription
  };
  
  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
};

// Custom hook to use the subscription context
export const useSubscription = () => {
  const context = useContext(SubscriptionContext);
  if (context === null) {
    throw new Error('useSubscription must be used within a SubscriptionProvider');
  }
  return context;
};

export default SubscriptionContext; 