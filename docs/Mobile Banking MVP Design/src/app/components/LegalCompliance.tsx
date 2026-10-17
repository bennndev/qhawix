import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, FileText, Shield, Eye, Download, Trash2, AlertCircle } from 'lucide-react';

interface LegalComplianceProps {
  onBack: () => void;
}

export const LegalCompliance: React.FC<LegalComplianceProps> = ({ onBack }) => {
  const [consents, setConsents] = React.useState({
    dataProcessing: true,
    biometricData: true,
    geolocation: true,
    aiAnalysis: true,
    thirdPartySharing: false,
  });

  const arcoRights = [
    {
      right: 'Access',
      description: 'Request a copy of your personal data',
      icon: Eye,
      action: 'Request Data',
    },
    {
      right: 'Rectification',
      description: 'Correct inaccurate information',
      icon: FileText,
      action: 'Update Info',
    },
    {
      right: 'Cancellation',
      description: 'Request deletion of your data',
      icon: Trash2,
      action: 'Delete Data',
    },
    {
      right: 'Opposition',
      description: 'Object to certain data processing',
      icon: AlertCircle,
      action: 'File Objection',
    },
  ];

  const regulations = [
    {
      law: 'Law 29733',
      title: 'Personal Data Protection Law (Peru)',
      description: 'Compliance with Peruvian data protection regulations',
      status: 'Compliant',
    },
    {
      law: 'SBS Resolution',
      title: 'Banking Security Standards',
      description: 'Superintendency of Banking and Insurance requirements',
      status: 'Compliant',
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-gray-700 to-gray-900 pt-12 pb-8 px-6">
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Legal & Compliance</h1>
            <p className="text-gray-300 text-sm">Privacy rights & data control</p>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Compliance Status */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
              <Shield className="text-green-600" size={24} />
            </div>
            <div>
              <h3 className="text-gray-900">Compliance Status</h3>
              <p className="text-green-600 text-sm">Fully Compliant</p>
            </div>
          </div>

          <div className="space-y-3">
            {regulations.map((reg, index) => (
              <div key={index} className="p-3 bg-gray-50 rounded-xl">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-gray-900 text-sm">{reg.law}</p>
                  <span className="px-2 py-1 bg-green-100 text-green-700 rounded-full text-xs">
                    {reg.status}
                  </span>
                </div>
                <p className="text-gray-600 text-xs mb-1">{reg.title}</p>
                <p className="text-gray-500 text-xs">{reg.description}</p>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Your Consents */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Your Consents</h3>
          <p className="text-gray-600 text-sm mb-4">
            Manage what data we can collect and process according to Law 29733
          </p>

          <div className="space-y-3">
            <div className="p-4 bg-gray-50 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex-1">
                  <p className="text-gray-900 text-sm mb-1">Data Processing</p>
                  <p className="text-gray-600 text-xs">Basic account and transaction data</p>
                </div>
                <button
                  className="w-14 h-8 rounded-full bg-gray-300 relative cursor-not-allowed"
                  disabled
                >
                  <div className="w-6 h-6 bg-white rounded-full absolute top-1 left-7" />
                </button>
              </div>
              <p className="text-gray-500 text-xs italic">Required for service operation</p>
            </div>

            <div className="p-4 bg-gray-50 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex-1">
                  <p className="text-gray-900 text-sm mb-1">Biometric Data</p>
                  <p className="text-gray-600 text-xs">Fingerprint, voice, and facial recognition</p>
                </div>
                <button
                  onClick={() => setConsents({ ...consents, biometricData: !consents.biometricData })}
                  className={`w-14 h-8 rounded-full transition-colors relative ${
                    consents.biometricData ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
                  }`}
                >
                  <motion.div
                    className="w-6 h-6 bg-white rounded-full absolute top-1"
                    animate={{ left: consents.biometricData ? '28px' : '4px' }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                </button>
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex-1">
                  <p className="text-gray-900 text-sm mb-1">Geolocation Tracking</p>
                  <p className="text-gray-600 text-xs">Location-based security features</p>
                </div>
                <button
                  onClick={() => setConsents({ ...consents, geolocation: !consents.geolocation })}
                  className={`w-14 h-8 rounded-full transition-colors relative ${
                    consents.geolocation ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
                  }`}
                >
                  <motion.div
                    className="w-6 h-6 bg-white rounded-full absolute top-1"
                    animate={{ left: consents.geolocation ? '28px' : '4px' }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                </button>
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex-1">
                  <p className="text-gray-900 text-sm mb-1">AI Behavioral Analysis</p>
                  <p className="text-gray-600 text-xs">AURA Guardian security features</p>
                </div>
                <button
                  onClick={() => setConsents({ ...consents, aiAnalysis: !consents.aiAnalysis })}
                  className={`w-14 h-8 rounded-full transition-colors relative ${
                    consents.aiAnalysis ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
                  }`}
                >
                  <motion.div
                    className="w-6 h-6 bg-white rounded-full absolute top-1"
                    animate={{ left: consents.aiAnalysis ? '28px' : '4px' }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                </button>
              </div>
            </div>

            <div className="p-4 bg-gray-50 rounded-xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex-1">
                  <p className="text-gray-900 text-sm mb-1">Third-Party Data Sharing</p>
                  <p className="text-gray-600 text-xs">Marketing and analytics partners</p>
                </div>
                <button
                  onClick={() => setConsents({ ...consents, thirdPartySharing: !consents.thirdPartySharing })}
                  className={`w-14 h-8 rounded-full transition-colors relative ${
                    consents.thirdPartySharing ? 'bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4]' : 'bg-gray-300'
                  }`}
                >
                  <motion.div
                    className="w-6 h-6 bg-white rounded-full absolute top-1"
                    animate={{ left: consents.thirdPartySharing ? '28px' : '4px' }}
                    transition={{ type: 'spring', stiffness: 500, damping: 30 }}
                  />
                </button>
              </div>
            </div>
          </div>
        </motion.div>

        {/* ARCO Rights */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-2">Your ARCO Rights</h3>
          <p className="text-gray-600 text-sm mb-4">
            As per Law 29733, you have the following rights regarding your personal data:
          </p>

          <div className="space-y-3">
            {arcoRights.map((right, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div className="flex items-center gap-3 flex-1">
                  <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                    <right.icon className="text-blue-600" size={18} />
                  </div>
                  <div>
                    <p className="text-gray-900 text-sm mb-0.5">{right.right}</p>
                    <p className="text-gray-600 text-xs">{right.description}</p>
                  </div>
                </div>
                <button className="px-3 py-2 bg-white border border-gray-200 rounded-lg text-xs text-gray-700 hover:bg-gray-50 transition-colors whitespace-nowrap ml-2">
                  {right.action}
                </button>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Download Data */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Data Portability</h3>
          <p className="text-gray-600 text-sm mb-4">
            Download a complete copy of your data in a machine-readable format
          </p>
          <button className="w-full py-4 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-2xl flex items-center justify-center gap-2">
            <Download size={20} />
            Download My Data
          </button>
        </motion.div>

        {/* Legal Documents */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <h3 className="text-gray-900 mb-4">Legal Documents</h3>
          <div className="space-y-3">
            <button className="w-full p-4 bg-gray-50 hover:bg-gray-100 rounded-xl text-left transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="text-gray-600" size={20} />
                <div>
                  <p className="text-gray-900 text-sm">Privacy Policy</p>
                  <p className="text-gray-500 text-xs">Last updated: Nov 2025</p>
                </div>
              </div>
              <span className="text-gray-400">→</span>
            </button>

            <button className="w-full p-4 bg-gray-50 hover:bg-gray-100 rounded-xl text-left transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="text-gray-600" size={20} />
                <div>
                  <p className="text-gray-900 text-sm">Terms of Service</p>
                  <p className="text-gray-500 text-xs">Last updated: Nov 2025</p>
                </div>
              </div>
              <span className="text-gray-400">→</span>
            </button>

            <button className="w-full p-4 bg-gray-50 hover:bg-gray-100 rounded-xl text-left transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="text-gray-600" size={20} />
                <div>
                  <p className="text-gray-900 text-sm">Data Processing Agreement</p>
                  <p className="text-gray-500 text-xs">Last updated: Nov 2025</p>
                </div>
              </div>
              <span className="text-gray-400">→</span>
            </button>
          </div>
        </motion.div>

        {/* Contact DPO */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-2xl p-4 border border-blue-200"
        >
          <h3 className="text-blue-900 text-sm mb-2">Data Protection Officer</h3>
          <p className="text-blue-700 text-xs mb-3">
            For any privacy concerns or data-related inquiries, contact our DPO:
          </p>
          <p className="text-blue-800 text-xs">📧 dpo@bancoseguro.pe</p>
          <p className="text-blue-800 text-xs">📞 +51 1 234 5678</p>
        </motion.div>
      </div>
    </div>
  );
};
