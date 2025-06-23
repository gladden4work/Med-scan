import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { vi } from 'vitest';
import QuotaDisplay from './QuotaDisplay';
import { useAuth } from '../AuthContext';
import { useSubscription } from '../SubscriptionContext';

// Mock the hooks
vi.mock('../AuthContext', () => ({
  useAuth: vi.fn()
}));

vi.mock('../SubscriptionContext', () => ({
  useSubscription: vi.fn()
}));

describe('QuotaDisplay', () => {
  // Setup default mocks
  const mockNavigateTo = vi.fn();
  
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks();
    
    // Default mock implementations
    useAuth.mockReturnValue({
      user: { id: 'test-user-id' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(5),
      getQuotaLimit: vi.fn().mockReturnValue(10),
      getRemainingFailedScanQuota: vi.fn().mockReturnValue(2),
      getFailedScanQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
  });
  
  test('renders basic quota display correctly', () => {
    render(<QuotaDisplay featureKey="scan_quota" navigateTo={mockNavigateTo} />);
    
    expect(screen.getByText('Scan Limit: 5/10')).toBeInTheDocument();
  });
  
  test('renders medication limit correctly', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(2),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
    
    render(<QuotaDisplay featureKey="my_medication_limit" navigateTo={mockNavigateTo} />);
    
    expect(screen.getByText('Medication Limit: 2/3')).toBeInTheDocument();
  });
  
  test('renders history limit correctly', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(1),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
    
    render(<QuotaDisplay featureKey="scan_history_limit" navigateTo={mockNavigateTo} />);
    
    expect(screen.getByText('History Limit: 1/3')).toBeInTheDocument();
  });
  
  test('renders failed scan quota when showFailedScanQuota is true', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(5),
      getQuotaLimit: vi.fn().mockReturnValue(10),
      getRemainingFailedScanQuota: vi.fn().mockReturnValue(2),
      getFailedScanQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota" 
        navigateTo={mockNavigateTo}
        showFailedScanQuota={true}
      />
    );
    
    expect(screen.getByText('Scan Limit: 5/10')).toBeInTheDocument();
    expect(screen.getByText('Failed Scan Quota: 2/3')).toBeInTheDocument();
  });
  
  test('does not render failed scan quota when showFailedScanQuota is false', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(5),
      getQuotaLimit: vi.fn().mockReturnValue(10),
      getRemainingFailedScanQuota: vi.fn().mockReturnValue(2),
      getFailedScanQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota" 
        navigateTo={mockNavigateTo}
        showFailedScanQuota={false}
      />
    );
    
    expect(screen.getByText('Scan Limit: 5/10')).toBeInTheDocument();
    expect(screen.queryByText('Failed Scan Quota: 2/3')).not.toBeInTheDocument();
  });
  
  test('shows upgrade button for free users', () => {
    useAuth.mockReturnValue({
      user: { id: 'test-user-id' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(5),
      getQuotaLimit: vi.fn().mockReturnValue(10),
      currentPlan: { price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota" 
        navigateTo={mockNavigateTo}
        showUpgradeButton={true}
      />
    );
    
    expect(screen.getByText('Upgrade')).toBeInTheDocument();
  });
  
  test('does not show upgrade button for premium users', () => {
    useAuth.mockReturnValue({
      user: { id: 'test-user-id' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(5),
      getQuotaLimit: vi.fn().mockReturnValue(10),
      currentPlan: { price: 9.99 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota" 
        navigateTo={mockNavigateTo}
        showUpgradeButton={true}
      />
    );
    
    expect(screen.queryByText('Upgrade')).not.toBeInTheDocument();
  });
  
  test('shows login button for anonymous users with no remaining quota', () => {
    useAuth.mockReturnValue({
      user: null
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(0),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota" 
        navigateTo={mockNavigateTo}
      />
    );
    
    expect(screen.getByText('Log in')).toBeInTheDocument();
  });
}); 