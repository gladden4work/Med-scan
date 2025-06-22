import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from './supabaseClient';
import { useAuth } from './AuthContext';

// Create context
const SubscriptionContext = createContext(null);

// Default entitlements for non-logged in users
const DEFAULT_ANONYMOUS_ENTITLEMENTS = {
  scan_quota: { limit: 3, used: 0, refresh: 'daily' },
  followup_questions: { limit: 0, used: 0, refresh: 'daily' },
  history_access: { limit: 0, used: 0, refresh: null },
  medication_list: { limit: 0, used: 0, refresh: null },
  ads_enabled: { value: 1, refresh: null }
};

// Default entitlements for logged in users with no subscription
const DEFAULT_FREE_ENTITLEMENTS = {
  scan_quota: { limit: 5, used: 0, refresh: 'daily' },
  followup_questions: { limit: 3, used: 0, refresh: 'daily' },
  history_access: { limit: 3, used: 0, refresh: null },
  medication_list: { limit: 3, used: 0, refresh: null },
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
    if (!feature) return '0 / 0';
    
    return `${feature.limit - feature.used} / ${feature.limit}`;
  };
  
  // Get remaining quota
  const getRemainingQuota = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature) return 0;
    
    return Math.max(0, feature.limit - feature.used);
  };
  
  // Check if ads should be shown
  const shouldShowAds = () => {
    const adsFeature = entitlements.ads_enabled;
    return adsFeature && adsFeature.value === 1;
  };
  
  // Get refresh period text
  const getRefreshPeriodText = (featureKey) => {
    const feature = entitlements[featureKey];
    if (!feature || !feature.refresh) return '';
    
    return feature.refresh === 'daily' 
      ? 'Refreshes daily at midnight' 
      : 'Refreshes monthly';
  };
  
  return (
    <SubscriptionContext.Provider
      value={{
        currentPlan,
        entitlements,
        availablePlans,
        loading,
        checkEntitlement,
        incrementUsage,
        subscribeToPlan,
        cancelSubscription,
        formatQuotaDisplay,
        getRemainingQuota,
        shouldShowAds,
        getRefreshPeriodText
      }}
    >
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