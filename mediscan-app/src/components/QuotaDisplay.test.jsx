import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { vi } from 'vitest';
import QuotaDisplay from './QuotaDisplay';
import { useAuth } from '../AuthContext';
import { useSubscription } from '../SubscriptionContext';

// Mock the hooks
vi.mock('../AuthContext');
vi.mock('../SubscriptionContext');

describe('QuotaDisplay Component', () => {
  const mockNavigateTo = vi.fn();
  
  beforeEach(() => {
    mockNavigateTo.mockClear();
    
    // Default mock implementations
    useAuth.mockReturnValue({
      user: null
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(2),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { name: 'Free (Not Logged In)', price: 0 }
    });
  });
  
  test('renders correctly for non-logged in users with remaining quota', () => {
    render(
      <QuotaDisplay 
        featureKey="scan_quota"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Should show "Scan Limit: 2/3" without login button
    expect(screen.getByText('Scan Limit: 2/3')).toBeInTheDocument();
    expect(screen.queryByText('Log in')).not.toBeInTheDocument();
  });
  
  test('renders correctly for non-logged in users with no remaining quota', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(0),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { name: 'Free (Not Logged In)', price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Should show "Scan Limit: 0/3" with login button
    expect(screen.getByText('Scan Limit: 0/3')).toBeInTheDocument();
    expect(screen.getByText('Log in')).toBeInTheDocument();
  });
  
  test('login button navigates to auth page when clicked', () => {
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(0),
      getQuotaLimit: vi.fn().mockReturnValue(3),
      currentPlan: { name: 'Free (Not Logged In)', price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="scan_quota"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Click the login button
    fireEvent.click(screen.getByText('Log in'));
    
    // Should navigate to auth page
    expect(mockNavigateTo).toHaveBeenCalledWith('auth');
  });
  
  test('renders correctly for free logged-in users', () => {
    useAuth.mockReturnValue({
      user: { id: 'user-123' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(4),
      getQuotaLimit: vi.fn().mockReturnValue(5),
      currentPlan: { name: 'Free (Logged In)', price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="medication_list"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Should show "Medication Limit: 4/5" with upgrade button
    expect(screen.getByText('Medication Limit: 4/5')).toBeInTheDocument();
    expect(screen.getByText('Upgrade')).toBeInTheDocument();
  });
  
  test('upgrade button navigates to subscription page when clicked', () => {
    useAuth.mockReturnValue({
      user: { id: 'user-123' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(4),
      getQuotaLimit: vi.fn().mockReturnValue(5),
      currentPlan: { name: 'Free (Logged In)', price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="medication_list"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Click the upgrade button
    fireEvent.click(screen.getByText('Upgrade'));
    
    // Should navigate to subscription page
    expect(mockNavigateTo).toHaveBeenCalledWith('subscription');
  });
  
  test('renders correctly for premium users', () => {
    useAuth.mockReturnValue({
      user: { id: 'user-123' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(50),
      getQuotaLimit: vi.fn().mockReturnValue(999),
      currentPlan: { name: 'Premium', price: 9.99 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="followup_questions"
        navigateTo={mockNavigateTo}
      />
    );
    
    // Should show "Question Limit: 50/999" without upgrade button
    expect(screen.getByText('Question Limit: 50/999')).toBeInTheDocument();
    expect(screen.queryByText('Upgrade')).not.toBeInTheDocument();
  });
  
  test('does not show upgrade button when showUpgradeButton is false', () => {
    useAuth.mockReturnValue({
      user: { id: 'user-123' }
    });
    
    useSubscription.mockReturnValue({
      getRemainingQuota: vi.fn().mockReturnValue(4),
      getQuotaLimit: vi.fn().mockReturnValue(5),
      currentPlan: { name: 'Free (Logged In)', price: 0 }
    });
    
    render(
      <QuotaDisplay 
        featureKey="history_access"
        showUpgradeButton={false}
        navigateTo={mockNavigateTo}
      />
    );
    
    // Should show "History Limit: 4/5" without upgrade button
    expect(screen.getByText('History Limit: 4/5')).toBeInTheDocument();
    expect(screen.queryByText('Upgrade')).not.toBeInTheDocument();
  });
  
  test('applies custom className correctly', () => {
    render(
      <QuotaDisplay 
        featureKey="scan_quota"
        className="custom-class"
        navigateTo={mockNavigateTo}
      />
    );
    
    // The component should have the custom class
    const component = screen.getByText('Scan Limit: 2/3').closest('div');
    expect(component).toHaveClass('custom-class');
  });
}); 