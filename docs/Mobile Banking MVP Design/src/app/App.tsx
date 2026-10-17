import React from 'react';
import { Login } from './components/Login';
import { PinEntry } from './components/PinEntry';
import { Dashboard } from './components/Dashboard';
import { Transfer } from './components/Transfer';
import { VoiceVerification } from './components/VoiceVerification';
import { GestureVerification } from './components/GestureVerification';
import { DualOutcome } from './components/DualOutcome';
import { SecurityHub } from './components/SecurityHub';
import { HighBalanceProtection } from './components/HighBalanceProtection';
import { UltraSecureMode } from './components/UltraSecureMode';
import { Geolocation } from './components/Geolocation';
import { TrustedContacts } from './components/TrustedContacts';
import { LegalCompliance } from './components/LegalCompliance';
import { DecoyAccountMode } from './components/DecoyAccountMode';
import { VoiceCommandTraining } from './components/VoiceCommandTraining';
import { AnomalyEvidence } from './components/AnomalyEvidence';
import { DataMasking } from './components/DataMasking';
import { AuraFloatingButton } from './components/AuraFloatingButton';
import { AuraChat } from './components/AuraChat';
import { UltraSecureLockedView } from './components/UltraSecureLockedView';
import { SecureModePanel } from './components/SecureModePanel';

type Screen = 
  | 'login' 
  | 'pin' 
  | 'dashboard' 
  | 'transfer' 
  | 'voice-verification' 
  | 'gesture-verification'
  | 'dual-outcome'
  | 'security-hub'
  | 'high-balance'
  | 'ultra-secure'
  | 'geolocation'
  | 'trusted-contacts'
  | 'legal-compliance'
  | 'decoy-account'
  | 'voice-training'
  | 'anomaly-evidence'
  | 'data-masking'
  | 'ultra-secure-locked';

interface TransferData {
  recipient: string;
  amount: number;
  concept: string;
}

interface AIResults {
  voice: 'normal' | 'stress';
  gesture: 'valid' | 'abnormal';
}

function App() {
  const [currentScreen, setCurrentScreen] = React.useState<Screen>('login');
  const [sdkActive, setSDKActive] = React.useState(false);
  const [balance, setBalance] = React.useState(15432.75);
  const [transferData, setTransferData] = React.useState<TransferData | null>(null);
  const [aiResults, setAIResults] = React.useState<AIResults>({
    voice: 'normal',
    gesture: 'valid',
  });
  const [ultraSecureMode, setUltraSecureMode] = React.useState(false);
  const [geolocationEnabled, setGeolocationEnabled] = React.useState(true);
  const [trustedContactsCount, setTrustedContactsCount] = React.useState(2);
  const [voiceProfileSetup, setVoiceProfileSetup] = React.useState(false);
  const [auraChatOpen, setAuraChatOpen] = React.useState(false);
  const [auraHasNotification, setAuraHasNotification] = React.useState(false);
  const [securePanelOpen, setSecurePanelOpen] = React.useState(false);

  const userName = 'Jorge Pino';
  const SUSPICIOUS_THRESHOLD = 2000;
  const ULTRA_SECURE_END_TIME = '06:00';

  // Check if we should show ultra secure locked view
  React.useEffect(() => {
    const checkUltraSecureSchedule = () => {
      const now = new Date();
      const currentHour = now.getHours();
      
      // Auto-activate between 23:00 and 06:00
      if ((currentHour >= 23 || currentHour < 6) && !ultraSecureMode) {
        setUltraSecureMode(true);
        if (currentScreen === 'dashboard') {
          setCurrentScreen('ultra-secure-locked');
        }
      }
    };

    checkUltraSecureSchedule();
    const interval = setInterval(checkUltraSecureSchedule, 60000); // Check every minute
    return () => clearInterval(interval);
  }, [currentScreen, ultraSecureMode]);

  const handleSDKActivate = () => {
    setSDKActive(true);
    // Log to console to simulate backend event
    console.log('🔐 AURA Guardian SDK Activated', {
      event: 'guardian_mode_on',
      user: userName.toLowerCase().replace(' ', '_'),
      trigger: 'manual',
      timestamp: new Date().toISOString(),
    });
  };

  const handleLogin = (method: 'fingerprint' | 'pin') => {
    if (method === 'fingerprint') {
      // Direct to dashboard
      setTimeout(() => setCurrentScreen('dashboard'), 500);
    } else {
      // Show PIN entry
      setCurrentScreen('pin');
    }
  };

  const handlePinComplete = (pin: string) => {
    // In a real app, verify PIN here
    setTimeout(() => setCurrentScreen('dashboard'), 300);
  };

  const handleTransferConfirm = (data: TransferData) => {
    setTransferData(data);

    // Check if transaction is suspicious
    if (data.amount > SUSPICIOUS_THRESHOLD) {
      // Activate SDK and start AI flow
      console.log('🚨 Suspicious transaction detected', {
        event: 'guardian_mode_on',
        user: userName.toLowerCase().replace(' ', '_'),
        trigger: 'transaction',
        amount: data.amount,
        threshold: SUSPICIOUS_THRESHOLD,
        timestamp: new Date().toISOString(),
      });
      setSDKActive(true);
      setCurrentScreen('voice-verification');
    } else {
      // Process normal transfer
      setBalance(balance - data.amount);
      // Could show success screen here
      setTimeout(() => setCurrentScreen('dashboard'), 1000);
    }
  };

  const handleVoiceComplete = (result: 'normal' | 'stress') => {
    setAIResults((prev) => ({ ...prev, voice: result }));
    
    console.log('🎤 Voice verification complete', {
      result,
      timestamp: new Date().toISOString(),
    });

    if (result === 'normal') {
      // Voice passed, complete transaction
      if (transferData) {
        setBalance(balance - transferData.amount);
      }
      setCurrentScreen('dashboard');
    } else {
      // Voice suspicious, proceed to gesture check
      setCurrentScreen('gesture-verification');
    }
  };

  const handleGestureComplete = (result: 'valid' | 'abnormal') => {
    setAIResults((prev) => ({ ...prev, gesture: result }));
    
    console.log('📸 Gesture verification complete', {
      result,
      timestamp: new Date().toISOString(),
    });

    if (result === 'valid' && aiResults.voice === 'normal') {
      // All checks passed
      if (transferData) {
        setBalance(balance - transferData.amount);
      }
      setCurrentScreen('dashboard');
    } else {
      // Gesture suspicious or combined suspicious, trigger dual outcome
      setCurrentScreen('dual-outcome');
    }
  };

  const handleDualOutcomeComplete = () => {
    // Return to dashboard (transaction was blocked)
    setCurrentScreen('dashboard');
    setTransferData(null);
    setAIResults({ voice: 'normal', gesture: 'valid' });
  };

  const handleFeatureSelect = (feature: string) => {
    switch (feature) {
      case 'high-balance':
        setCurrentScreen('high-balance');
        break;
      case 'ultra-secure':
        setCurrentScreen('ultra-secure');
        break;
      case 'geolocation':
        setCurrentScreen('geolocation');
        break;
      case 'trusted-contacts':
        setCurrentScreen('trusted-contacts');
        break;
      case 'legal-compliance':
        setCurrentScreen('legal-compliance');
        break;
      case 'decoy-account':
        setCurrentScreen('decoy-account');
        break;
      case 'voice-control':
        setCurrentScreen('voice-training');
        break;
      case 'data-masking':
        setCurrentScreen('data-masking');
        break;
      case 'anomaly-detection':
        setCurrentScreen('anomaly-evidence');
        break;
      default:
        break;
    }
  };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'login':
        return <Login onLogin={handleLogin} onSDKActivate={handleSDKActivate} />;
      
      case 'pin':
        return <PinEntry onComplete={handlePinComplete} onSDKActivate={handleSDKActivate} />;
      
      case 'dashboard':
        return (
          <Dashboard
            onTransfer={() => setCurrentScreen('transfer')}
            onSecurity={() => setCurrentScreen('security-hub')}
            balance={balance}
            sdkActive={sdkActive}
            onSecureMode={() => setSecurePanelOpen(true)}
          />
        );
      
      case 'transfer':
        return (
          <Transfer
            onBack={() => setCurrentScreen('dashboard')}
            onConfirm={handleTransferConfirm}
          />
        );
      
      case 'voice-verification':
        return transferData ? (
          <VoiceVerification
            userName={userName}
            amount={transferData.amount}
            recipient={transferData.recipient}
            onComplete={handleVoiceComplete}
          />
        ) : null;
      
      case 'gesture-verification':
        return <GestureVerification onComplete={handleGestureComplete} />;
      
      case 'dual-outcome':
        return transferData ? (
          <DualOutcome
            userName={userName}
            amount={transferData.amount}
            recipient={transferData.recipient}
            voiceResult={aiResults.voice}
            gestureResult={aiResults.gesture}
            onComplete={handleDualOutcomeComplete}
          />
        ) : null;
      
      case 'security-hub':
        return (
          <SecurityHub
            onBack={() => setCurrentScreen('dashboard')}
            onFeatureSelect={handleFeatureSelect}
            securityStatus={{
              ultraSecureMode,
              geolocation: geolocationEnabled,
              trustedContacts: trustedContactsCount,
              voiceProfile: voiceProfileSetup,
            }}
          />
        );
      
      case 'high-balance':
        return (
          <HighBalanceProtection
            onBack={() => setCurrentScreen('security-hub')}
            balance={balance}
          />
        );
      
      case 'ultra-secure':
        return (
          <UltraSecureMode
            onBack={() => setCurrentScreen('security-hub')}
            isActive={ultraSecureMode}
            onToggle={setUltraSecureMode}
          />
        );
      
      case 'geolocation':
        return (
          <Geolocation
            onBack={() => setCurrentScreen('security-hub')}
          />
        );
      
      case 'trusted-contacts':
        return (
          <TrustedContacts
            onBack={() => setCurrentScreen('security-hub')}
          />
        );
      
      case 'legal-compliance':
        return (
          <LegalCompliance
            onBack={() => setCurrentScreen('security-hub')}
          />
        );
      
      case 'decoy-account':
        return (
          <DecoyAccountMode
            onBack={() => setCurrentScreen('security-hub')}
            realBalance={balance}
          />
        );
      
      case 'voice-training':
        return (
          <VoiceCommandTraining
            onBack={() => setCurrentScreen('security-hub')}
            onComplete={() => {
              setVoiceProfileSetup(true);
              setCurrentScreen('security-hub');
            }}
          />
        );
      
      case 'anomaly-evidence':
        return (
          <AnomalyEvidence
            onBack={() => setCurrentScreen('dashboard')}
            onBlock={() => {
              console.log('Account blocked');
              setCurrentScreen('dashboard');
            }}
            onConfirm={() => {
              console.log('Activity confirmed');
              setCurrentScreen('dashboard');
            }}
          />
        );
      
      case 'data-masking':
        return (
          <DataMasking
            onBack={() => setCurrentScreen('security-hub')}
          />
        );
      
      case 'ultra-secure-locked':
        return (
          <UltraSecureLockedView
            userName={userName}
            endTime={ULTRA_SECURE_END_TIME}
            onUnlock={() => {
              // In real app, would require biometric authentication
              setUltraSecureMode(false);
              setCurrentScreen('dashboard');
            }}
          />
        );
      
      default:
        return <Login onLogin={handleLogin} onSDKActivate={handleSDKActivate} />;
    }
  };

  const getChatContext = (): 'dashboard' | 'transfer' | 'security' | 'alert' => {
    if (currentScreen === 'transfer') return 'transfer';
    if (currentScreen.includes('security') || currentScreen.includes('hub')) return 'security';
    if (currentScreen.includes('anomaly') || currentScreen.includes('evidence')) return 'alert';
    return 'dashboard';
  };

  const getAuraState = (): 'idle' | 'listening' | 'scanning' | 'alert' | 'stealth' => {
    if (sdkActive) return 'stealth';
    if (currentScreen.includes('voice')) return 'listening';
    if (currentScreen.includes('gesture')) return 'scanning';
    if (currentScreen.includes('anomaly')) return 'alert';
    return 'idle';
  };

  const showAuraButton = currentScreen !== 'login' && currentScreen !== 'pin';

  const handleSecurePanelNavigate = (module: string) => {
    switch (module) {
      case 'ultra-secure':
        setCurrentScreen('ultra-secure');
        break;
      case 'geolocation':
        setCurrentScreen('geolocation');
        break;
      case 'voice-training':
        setCurrentScreen('voice-training');
        break;
      case 'legal-compliance':
        setCurrentScreen('legal-compliance');
        break;
      default:
        setCurrentScreen('security-hub');
    }
  };

  return (
    <div className="w-full max-w-[390px] mx-auto h-screen overflow-hidden bg-white relative">
      {renderScreen()}
      
      {/* AURA Floating Button - Persistent across all screens except login/pin */}
      {showAuraButton && (
        <>
          <AuraFloatingButton
            onClick={() => setAuraChatOpen(!auraChatOpen)}
            state={getAuraState()}
            hasNotification={auraHasNotification}
            onSecureMode={() => setSecurePanelOpen(true)}
          />
          
          <AuraChat
            isOpen={auraChatOpen}
            onClose={() => setAuraChatOpen(false)}
            onVoiceMode={() => {
              setAuraChatOpen(false);
              // In real app, would activate voice mode
              console.log('Voice mode activated');
            }}
            userName={userName}
            context={getChatContext()}
          />

          {/* Secure Mode Panel - Right side floating panel */}
          <SecureModePanel
            isOpen={securePanelOpen}
            onClose={() => setSecurePanelOpen(false)}
            ultraSecureMode={ultraSecureMode}
            onToggleUltraSecure={() => {
              setUltraSecureMode(!ultraSecureMode);
              if (!ultraSecureMode) {
                // Activating - show notification
                setAuraHasNotification(true);
                setTimeout(() => setAuraHasNotification(false), 3000);
              }
            }}
            onNavigateToConfig={handleSecurePanelNavigate}
          />
        </>
      )}
    </div>
  );
}

export default App;
