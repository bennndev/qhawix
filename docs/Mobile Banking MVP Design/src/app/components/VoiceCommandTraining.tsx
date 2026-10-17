import React from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Mic, Check, Volume2 } from 'lucide-react';
import { OwlIcon } from './OwlIcon';

interface VoiceCommandTrainingProps {
  onBack: () => void;
  onComplete: () => void;
}

export const VoiceCommandTraining: React.FC<VoiceCommandTrainingProps> = ({ onBack, onComplete }) => {
  const [currentStep, setCurrentStep] = React.useState(0);
  const [isRecording, setIsRecording] = React.useState(false);
  const [completedSteps, setCompletedSteps] = React.useState<number[]>([]);

  const trainingPhrases = [
    {
      id: 1,
      phrase: 'Activar modo ultra seguro',
      description: 'Activa restricciones nocturnas',
      category: 'Seguridad',
    },
    {
      id: 2,
      phrase: 'Bloquear todas las transacciones',
      description: 'Bloqueo de emergencia total',
      category: 'Emergencia',
    },
    {
      id: 3,
      phrase: 'Mostrar cuentas reales',
      description: 'Desactiva modo señuelo',
      category: 'Autenticación',
    },
    {
      id: 4,
      phrase: 'Alertar contactos de confianza',
      description: 'Notifica a tu red de seguridad',
      category: 'Alertas',
    },
    {
      id: 5,
      phrase: 'Activar modo emergencia',
      description: 'Rastreo continuo + alertas',
      category: 'Emergencia',
    },
  ];

  const handleRecord = (stepIndex: number) => {
    setIsRecording(true);
    setCurrentStep(stepIndex);

    // Simulate recording
    setTimeout(() => {
      setIsRecording(false);
      setCompletedSteps([...completedSteps, stepIndex]);
      
      if (stepIndex === trainingPhrases.length - 1) {
        // All steps completed
        setTimeout(() => {
          onComplete();
        }, 1000);
      }
    }, 3000);
  };

  const currentPhrase = trainingPhrases[currentStep];
  const progress = (completedSteps.length / trainingPhrases.length) * 100;

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
            <h1 className="text-white text-2xl">Entrenamiento de Voz</h1>
            <p className="text-cyan-200 text-sm">Configura comandos biométricos</p>
          </div>
        </div>

        {/* Progress */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-4 border border-white/20">
          <div className="flex items-center justify-between mb-2">
            <span className="text-cyan-200 text-sm">Progreso del entrenamiento</span>
            <span className="text-white">{completedSteps.length}/{trainingPhrases.length}</span>
          </div>
          <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-gradient-to-r from-green-400 to-cyan-400"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.5 }}
            />
          </div>
        </div>
      </div>

      <div className="px-6 -mt-4 relative z-10 space-y-4">
        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-gradient-to-r from-cyan-50 to-blue-50 rounded-2xl p-4 border border-cyan-200"
        >
          <div className="flex items-start gap-3">
            <Volume2 className="text-blue-600 flex-shrink-0 mt-0.5" size={20} />
            <div>
              <h3 className="text-blue-900 text-sm mb-1">Cómo funciona</h3>
              <p className="text-blue-700 text-xs">
                AURA aprenderá tu voz para autenticación biométrica. Di cada frase claramente 
                en un ambiente silencioso. Tu perfil de voz es único y seguro.
              </p>
            </div>
          </div>
        </motion.div>

        {/* Current Recording */}
        {isRecording && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-3xl p-8 shadow-lg border-2 border-purple-200"
          >
            <div className="text-center">
              <div className="mb-6">
                <OwlIcon state="listening" size={64} />
              </div>
              
              <h3 className="text-gray-900 text-lg mb-2">Escuchando...</h3>
              <p className="text-purple-600 mb-6 text-xl">{currentPhrase.phrase}</p>

              {/* Waveform Animation */}
              <div className="flex items-center justify-center gap-1 h-16">
                {[...Array(12)].map((_, i) => (
                  <motion.div
                    key={i}
                    className="w-1 bg-gradient-to-t from-purple-500 to-cyan-400 rounded-full"
                    animate={{
                      height: ['20%', '100%', '20%'],
                    }}
                    transition={{
                      duration: 0.8,
                      repeat: Infinity,
                      delay: i * 0.1,
                    }}
                  />
                ))}
              </div>

              <p className="text-gray-500 text-sm mt-4">Di la frase claramente...</p>
            </div>
          </motion.div>
        )}

        {/* Phrases List */}
        {!isRecording && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-2xl p-6 shadow-sm"
          >
            <h3 className="text-gray-900 mb-4">Comandos de Voz</h3>
            <div className="space-y-3">
              {trainingPhrases.map((phrase, index) => {
                const isCompleted = completedSteps.includes(index);
                const isCurrent = currentStep === index && !isCompleted;

                return (
                  <motion.div
                    key={phrase.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.05 }}
                    className={`p-4 rounded-xl border-2 transition-all ${
                      isCompleted
                        ? 'bg-green-50 border-green-300'
                        : isCurrent
                        ? 'bg-purple-50 border-purple-300'
                        : 'bg-gray-50 border-gray-200'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`px-2 py-0.5 rounded-full text-xs ${
                            phrase.category === 'Emergencia'
                              ? 'bg-red-100 text-red-700'
                              : phrase.category === 'Seguridad'
                              ? 'bg-blue-100 text-blue-700'
                              : 'bg-purple-100 text-purple-700'
                          }`}>
                            {phrase.category}
                          </span>
                        </div>
                        <p className="text-gray-900 mb-0.5">{phrase.phrase}</p>
                        <p className="text-gray-600 text-xs">{phrase.description}</p>
                      </div>

                      {isCompleted ? (
                        <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center flex-shrink-0 ml-3">
                          <Check className="text-white" size={20} />
                        </div>
                      ) : (
                        <motion.button
                          onClick={() => handleRecord(index)}
                          className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ml-3 ${
                            isCurrent
                              ? 'bg-gradient-to-r from-purple-500 to-pink-500'
                              : 'bg-gray-300 hover:bg-gray-400'
                          }`}
                          whileTap={{ scale: 0.95 }}
                        >
                          <Mic className="text-white" size={20} />
                        </motion.button>
                      )}
                    </div>
                  </motion.div>
                );
              })}
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
          <h3 className="text-orange-900 text-sm mb-2">Seguridad del Perfil de Voz</h3>
          <div className="space-y-1">
            <p className="text-orange-700 text-xs">• Tu voz se procesa localmente en el dispositivo</p>
            <p className="text-orange-700 text-xs">• Los datos biométricos están encriptados</p>
            <p className="text-orange-700 text-xs">• Puedes eliminar tu perfil en cualquier momento</p>
            <p className="text-orange-700 text-xs">• Se requiere confirmación dual para cambios</p>
          </div>
        </motion.div>

        {/* Complete Button */}
        {completedSteps.length === trainingPhrases.length && (
          <motion.button
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            onClick={onComplete}
            className="w-full py-4 bg-gradient-to-r from-green-500 to-emerald-500 text-white rounded-2xl shadow-lg"
            whileTap={{ scale: 0.98 }}
          >
            ✓ Completar Entrenamiento
          </motion.button>
        )}
      </div>
    </div>
  );
};
