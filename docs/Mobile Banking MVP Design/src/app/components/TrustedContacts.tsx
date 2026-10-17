import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, UserPlus, Shield, Eye, Phone, Mail, AlertTriangle } from 'lucide-react';

interface TrustedContactsProps {
  onBack: () => void;
}

interface Contact {
  id: string;
  name: string;
  phone: string;
  email: string;
  relationship: string;
  verified: boolean;
  permissions: string[];
}

export const TrustedContacts: React.FC<TrustedContactsProps> = ({ onBack }) => {
  const [contacts, setContacts] = React.useState<Contact[]>([
    {
      id: '1',
      name: 'María Pino',
      phone: '+51 987 654 321',
      email: 'maria.pino@email.com',
      relationship: 'Sister',
      verified: true,
      permissions: ['view-only', 'receive-alerts'],
    },
    {
      id: '2',
      name: 'Carlos Mendoza',
      phone: '+51 912 345 678',
      email: 'carlos.m@email.com',
      relationship: 'Best Friend',
      verified: true,
      permissions: ['receive-alerts'],
    },
  ]);

  const [showAddContact, setShowAddContact] = React.useState(false);

  const permissionTypes = [
    {
      id: 'view-only',
      label: 'Emergency View Access',
      description: 'Can view balance with special PIN',
      icon: Eye,
    },
    {
      id: 'receive-alerts',
      label: 'Receive Security Alerts',
      description: 'Notified of suspicious activity',
      icon: AlertTriangle,
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50 overflow-y-auto pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#0033CC] to-[#001A66] pt-12 pb-8 px-6">
        <div className="flex items-center gap-4 mb-6">
          <motion.button
            onClick={onBack}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm"
            whileTap={{ scale: 0.95 }}
          >
            <ArrowLeft className="text-white" size={20} />
          </motion.button>
          <div>
            <h1 className="text-white text-2xl">Trusted Contacts</h1>
            <p className="text-cyan-200 text-sm">Emergency access network</p>
          </div>
        </div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-cyan-200 text-sm mb-1">Active Contacts</p>
              <p className="text-white text-3xl">{contacts.filter(c => c.verified).length}</p>
            </div>
            <div className="w-16 h-16 bg-white/10 rounded-full flex items-center justify-center">
              <Shield className="text-cyan-300" size={32} />
            </div>
          </div>
        </motion.div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <h3 className="text-blue-900 text-sm mb-2">How It Works</h3>
          <div className="space-y-2">
            <p className="text-blue-700 text-xs">
              • Contacts receive alerts when suspicious activity is detected
            </p>
            <p className="text-blue-700 text-xs">
              • Emergency access requires biometric verification from both parties
            </p>
            <p className="text-blue-700 text-xs">
              • All access attempts are logged and cannot be deleted
            </p>
          </div>
        </motion.div>

        {/* Contact List */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="bg-white rounded-2xl p-6 shadow-sm"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Your Contacts</h3>
            <motion.button
              onClick={() => setShowAddContact(!showAddContact)}
              className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-xl text-sm"
              whileTap={{ scale: 0.98 }}
            >
              <UserPlus size={16} />
              Add
            </motion.button>
          </div>

          <div className="space-y-4">
            {contacts.map((contact, index) => (
              <motion.div
                key={contact.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.1 + index * 0.05 }}
                className="border border-gray-200 rounded-2xl p-4"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-start gap-3">
                    <div className="w-12 h-12 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white">
                      {contact.name.charAt(0)}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="text-gray-900">{contact.name}</p>
                        {contact.verified && (
                          <div className="w-5 h-5 bg-green-500 rounded-full flex items-center justify-center">
                            <Shield className="text-white" size={12} />
                          </div>
                        )}
                      </div>
                      <p className="text-gray-500 text-sm">{contact.relationship}</p>
                    </div>
                  </div>
                </div>

                <div className="space-y-2 mb-3">
                  <div className="flex items-center gap-2 text-gray-600 text-sm">
                    <Phone size={14} />
                    <span>{contact.phone}</span>
                  </div>
                  <div className="flex items-center gap-2 text-gray-600 text-sm">
                    <Mail size={14} />
                    <span className="truncate">{contact.email}</span>
                  </div>
                </div>

                <div className="pt-3 border-t border-gray-100">
                  <p className="text-gray-600 text-xs mb-2">Permissions:</p>
                  <div className="flex flex-wrap gap-2">
                    {contact.permissions.map((perm) => {
                      const permType = permissionTypes.find(p => p.id === perm);
                      return (
                        <div
                          key={perm}
                          className="px-2 py-1 bg-blue-50 text-blue-700 rounded-lg text-xs flex items-center gap-1"
                        >
                          {permType && <permType.icon size={12} />}
                          {permType?.label.split(' ')[0]}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Add Contact Form */}
        {showAddContact && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-2xl p-6 shadow-sm"
          >
            <h3 className="text-gray-900 mb-4">Add New Contact</h3>
            <div className="space-y-4">
              <div>
                <label className="text-gray-700 text-sm mb-2 block">Full Name</label>
                <input
                  type="text"
                  placeholder="Enter contact name"
                  className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none"
                />
              </div>

              <div>
                <label className="text-gray-700 text-sm mb-2 block">Phone Number</label>
                <input
                  type="tel"
                  placeholder="+51 XXX XXX XXX"
                  className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none"
                />
              </div>

              <div>
                <label className="text-gray-700 text-sm mb-2 block">Email</label>
                <input
                  type="email"
                  placeholder="email@example.com"
                  className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none"
                />
              </div>

              <div>
                <label className="text-gray-700 text-sm mb-2 block">Relationship</label>
                <select className="w-full px-4 py-3 bg-gray-50 rounded-xl border border-gray-200 focus:border-[#0033CC] focus:outline-none">
                  <option>Family</option>
                  <option>Friend</option>
                  <option>Partner</option>
                  <option>Legal Guardian</option>
                </select>
              </div>

              <div>
                <label className="text-gray-700 text-sm mb-2 block">Permissions</label>
                <div className="space-y-3">
                  {permissionTypes.map((perm) => (
                    <div key={perm.id} className="flex items-start gap-3 p-3 bg-gray-50 rounded-xl">
                      <input type="checkbox" className="mt-1" />
                      <div className="flex-1">
                        <p className="text-gray-900 text-sm mb-0.5">{perm.label}</p>
                        <p className="text-gray-600 text-xs">{perm.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <button className="w-full py-4 bg-gradient-to-r from-[#3A0CA3] to-[#48CAE4] text-white rounded-2xl">
                Send Invitation
              </button>
            </div>
          </motion.div>
        )}

        {/* Security Notice */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-gradient-to-r from-orange-50 to-red-50 rounded-2xl p-4 border border-orange-200"
        >
          <div className="flex items-start gap-3">
            <Shield className="text-orange-600 flex-shrink-0 mt-0.5" size={20} />
            <div>
              <h3 className="text-orange-900 text-sm mb-2">Verification Required</h3>
              <p className="text-orange-700 text-xs">
                New contacts must complete biometric verification before gaining access.
                Both you and your contact will receive a verification code via SMS and email.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};
