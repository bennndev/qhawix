# 🎨 Banco Seguro IA - Visual Component Guide
## Design System & UI Patterns

---

## 📐 Layout System (390×844 px)

### **Standard Container:**
```
┌─────────────────────────────────────┐
│ ← Header          Profile 👤  🛡️   │  PT: 48px (12 + 36)
│   24px padding                      │
│                                     │
│ Main Content Area                   │  PX: 24px
│ (Scrollable)                        │  (both sides)
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│                                     │
│ AURA 🦉                             │  Fixed bottom-right
└─────────────────────────────────────┘  BR: 24px, BB: 24px
```

---

## 🎨 Color Palette

### **Primary Colors:**
```css
Deep Blue:    #0033CC  ████████  Main brand
Navy Dark:    #001A66  ████████  Headers

Gradient Signature:
  #3A0CA3 → #4361EE → #48CAE4
  Violeta   Índigo    Cian
  ████████  ████████  ████████
```

### **Status Colors:**
```css
Success:  #10B981  ████████  Completed actions
Warning:  #F59E0B  ████████  Alerts, cautions
Danger:   #EF4444  ████████  Errors, blocks
Info:     #3B82F6  ████████  Information
```

### **Ultra Secure Theme:**
```css
Dark Base:    #1a0b2e  ████████  Background start
Dark Mid:     #2d1b4e  ████████  Background mid
Dark End:     #1a0b2e  ████████  Background end
Purple Glow:  #3A0CA3  ████████  Accents
```

---

## 🦉 AURA Icon States

### **1. Idle (Default):**
```
    ╱◉   ◉╲
   ╱   ⌵   ╲
  ╱    v    ╲
 ╱___________╲
 
White owl, open eyes
Gentle pulse every 2s
Cyan shadow (opacity 30%)
```

### **2. Listening:**
```
    ╱◉   ◉╲
   ╱   ⌵   ╲     )))
  ╱    v    ╲   )))
 ╱___________╲ )))
 
Cyan rings expanding
Larger eyes
Voice waves (3 layers)
```

### **3. Scanning:**
```
    ╱◉ ▶ ◉╲
   ╱   ⌵   ╲
  ╱  ⟳ v    ╲
 ╱___________╲
 
Rotating purple halo
Moving eyes (scan effect)
Spinning animation
```

### **4. Alert:**
```
    ╱◉ ! ◉╲
   ╱   ⌵   ╲    !
  ╱    v    ╲
 ╱___________╲
 
Red glow (pulsing)
Notification badge
Shake animation (subtle)
```

### **5. Stealth:**
```
    ╱ ◉   ◉╲
   ╱   ⌵   ╲
  ╱    v    ╲
 ╱___________╲
 
10% opacity
Almost invisible
SDK active silently
```

---

## 💬 AURA Chat Interface

```
┌─────────────────────────────────────┐
│ AURA                    🎤   ✕     │
│ Asistente Inteligente              │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────┐    │
│  │ ¡Hola Jorge! 👋           │    │
│  │ Tu saldo está protegido.  │    │
│  │ ¿En qué puedo ayudarte?   │    │
│  │                           │    │
│  │ [Ver sugerencias]         │    │
│  │ [Estado de seguridad]     │    │
│  └───────────────────────────┘    │
│  10:23 AM                          │
│                                     │
│            ┌─────────────────┐    │
│            │ ¿Cuál es mi     │    │
│            │ saldo actual?   │    │
│            └─────────────────┘    │
│                        10:24 AM    │
│                                     │
│  ┌───────────────────────────┐    │
│  │ Tu saldo actual es        │    │
│  │ S/ 15,432.75 💰           │    │
│  │                           │    │
│  │ Detecté que supera tu     │    │
│  │ umbral configurado.       │    │
│  │ ¿Deseas transferir el     │    │
│  │ excedente?                │    │
│  │                           │    │
│  │ [Configurar] [Transferir] │    │
│  └───────────────────────────┘    │
│  10:24 AM                          │
│                                     │
├─────────────────────────────────────┤
│ Escribe un mensaje...      [Enviar]│
└─────────────────────────────────────┘
```

---

## 🔒 Secure Mode Panel

```
                ┌─────────────────────┐
                │ Modo Seguro      ✕ │
                │ Protección automática│
                ├─────────────────────┤
                │                     │
                │ ┌─────────────────┐│
                │ │ 🌙              ││
                │ │ Modo Ultra      ││
                │ │ Seguro          ││
                │ │                 ││
                │ │ Desactivado  ⚪→││
                │ └─────────────────┘│
                │                     │
                │ ⚠️ Es horario      │
                │    nocturno        │
                │                     │
                │ Configuración:      │
                │                     │
                │ ┌─────────────┐ → │
                │ │⏰ Horario    │   │
                │ └─────────────┘   │
                │                     │
                │ ┌─────────────┐ → │
                │ │📍 Ubicación  │   │
                │ └─────────────┘   │
                │                     │
                │ ┌─────────────┐ → │
                │ │🗣️ Voz       │   │
                │ └─────────────┘   │
                │                     │
                │ ┌─────────────┐ → │
                │ │📄 Privacidad │   │
                │ └─────────────┘   │
                │                     │
                │ ⏰ 23:15            │
                │ 🌙 Horario nocturno│
                └─────────────────────┘
```

---

## 🎯 Button Styles

### **Primary Button:**
```
┌─────────────────────────────────┐
│  Transferir Ahora               │
└─────────────────────────────────┘

Background: Gradient #0033CC → #001A66
Text: White
Padding: 16px 24px
Border-radius: 16px
Shadow: 0 4px 12px rgba(0, 51, 204, 0.3)
```

### **Secondary Button:**
```
┌─────────────────────────────────┐
│  Cancelar                       │
└─────────────────────────────────┘

Background: Transparent
Border: 2px solid #0033CC
Text: #0033CC
Padding: 14px 24px
Border-radius: 16px
```

### **Action Card Button:**
```
┌────────┐
│   💸   │
│Transferir│
└────────┘

Background: Gradient (varies)
Size: 64×64 px icon area
Text: 12px below icon
Border-radius: 16px
Shadow: 0 2px 8px rgba(0, 0, 0, 0.1)
```

---

## 📊 Cards & Containers

### **Balance Card (Glassmorphism):**
```
┌─────────────────────────────────────┐
│ Saldo Disponible                    │
│                                     │
│ S/ 15,432.75                        │
│                                     │
│ •••• •••• •••• 9010                │
│                                     │
│ Jorge Pino                          │
└─────────────────────────────────────┘

Background: rgba(255, 255, 255, 0.1)
Backdrop-filter: blur(10px)
Border: 1px solid rgba(255, 255, 255, 0.2)
Border-radius: 24px
Padding: 24px
Shadow: 0 8px 32px rgba(0, 0, 0, 0.1)
```

### **Transaction Item:**
```
┌─────────────────────────────────────┐
│ 🎵  Spotify Premium      -S/ 15.90  │
│     Nov 10                          │
└─────────────────────────────────────┘

Background: White
Border-radius: 16px
Padding: 16px
Shadow: 0 2px 4px rgba(0, 0, 0, 0.05)
```

### **Alert Card:**
```
┌─────────────────────────────────────┐
│ ⚠️  Actividad Inusual Detectada     │
│                                     │
│ Transferencia de S/ 5,850 a cuenta │
│ no registrada requiere verificación│
│                                     │
│ [Verificar Ahora]  [Cancelar]      │
└─────────────────────────────────────┘

Background: Gradient orange/red 50% → 20%
Border: 2px solid #F59E0B
Border-radius: 20px
Padding: 20px
```

---

## 🌙 Ultra Secure Locked View

```
┌─────────────────────────────────────┐
│                                     │
│         🦉 (80px)                   │
│      AURA animado                   │
│                                     │
│      🔒 (120px pulsante)            │
│                                     │
│   Modo Ultra Seguro                 │
│                                     │
│   🔒 Tus datos están protegidos     │
│                                     │
│   Se desactivará en:                │
│   ┌─────────────┐                  │
│   │  06  :  45  │                  │
│   │ horas  min  │                  │
│   └─────────────┘                  │
│                                     │
│   ┌───────────────────────────┐   │
│   │ Consultar Saldo Protegido │   │
│   │                           │   │
│   │ S/ •••••.••  (blur 8px)   │   │
│   └───────────────────────────┘   │
│                                     │
│   Historial:                        │
│   ┌───────────────────────────┐   │
│   │ Empresa protegida         │   │
│   │ -S/ •••.••       10 Nov   │   │
│   └───────────���───────────────┘   │
│                                     │
│   Restricciones Activas:            │
│   • Transferencias bloqueadas       │
│   • Datos ocultos                   │
│   • Nombres reemplazados            │
│                                     │
│   ┌───────────────────────────┐   │
│   │ 🔓 Desactivar Modo        │   │
│   │    (Requiere huella)      │   │
│   └───────────────────────────┘   │
│                                     │
│  💡 AURA: Tus datos financieros    │
│     están completamente protegidos │
│                                     │
└─────────────────────────────────────┘

Background: Gradient #1a0b2e → #2d1b4e
Particles: Floating (purple/blue)
Lock: Pulsing animation
Countdown: Tabular-nums font
All text: White/Cyan
```

---

## 👁️ Backend Demo View

```
┌─────────────────────────────────────┐
│ 🚨 Backend Demo              🔴    │
│    Vista del Operador               │
│    (Solo demostración)              │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────┐   │
│ │ ⚠️ Alerta de Seguridad      │   │
│ │ Fase 3 - Anomalía detectada  │   │
│ │───────────────────────────── │   │
│ │                             │   │
│ │ INFORMACIÓN DEL USUARIO     │   │
│ │ Usuario: Jorge Pino         │   │
│ │ Evento: Anomalía comportamiento│ │
│ │                             │   │
│ │ ANÁLISIS DE IA              │   │
│ │ Voz:    [Estrés] ⚠️  80%    │   │
│ │ Gesto:  [Irregular] ⚠️ 75%  │   │
│ │                             │   │
│ │ TRANSACCIÓN                 │   │
│ │ Monto: S/ 5,850.00          │   │
│ │ Destino: •••• 4521          │   │
│ │ Hora: 23:47                 │   │
│ │                             │   │
│ │ UBICACIÓN                   │   │
│ │ GPS: 📍 Arequipa, Perú      │   │
│ │ Coords: -16.4090, -71.5375  │   │
│ │ Dispositivo: iPhone 13 Pro  │   │
│ │ IP: 190.237.45.182          │   │
│ │                             │   │
│ │ ACCIÓN EJECUTADA            │   │
│ │ ✓ Transferencia BLOQUEADA   │   │
│ │ ✓ Usuario ve confirmación   │   │
│ │ ✓ Operadores notificados    │   │
│ └─────────────────────────────┘   │
│                                     │
│ ┌─────────────────────────────┐   │
│ │ 📡 Backend Event Log:       │   │
│ │ {                           │   │
│ │   "event": "phase_3",       │   │
│ │   "user": "jorge_pino",     │   │
│ │   "blocked": true,          │   │
│ │   ...                       │   │
│ │ }                           │   │
│ └─────────────────────────────┘   │
│                                     │
│ [Bloquear Cuenta Permanentemente]   │
│ [📞 Contactar Usuario]              │
│ [← Volver a Vista Usuario]         │
│ [Revisar Más Tarde]                 │
│                                     │
│ ℹ️ Solo operadores autorizados     │
│    acceden en producción            │
└─────────────────────────────────────┘

Background: Gradient red-950 → gray-900
Border: 2px solid red-500/50
Alert pulse: Red dot top-right
Cards: Black/80 backdrop-blur
Text: White/Green (log)
```

---

## 📱 Screen Templates

### **Login Screen:**
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         Banco Seguro IA             │
│                                     │
│     "Seguridad invisible.           │
│      Protección adaptativa."        │
│                                     │
│                                     │
│   ┌───────────────────────────┐   │
│   │  🔒                        │   │
│   │  Usar Huella Digital       │   │
│   └───────────────────────────┘   │
│                                     │
│   ┌───────────────────────────┐   │
│   │  🔢                        │   │
│   │  Ingresar con PIN          │   │
│   └───────────────────────────┘   │
│                                     │
│                                     │
│   Protegido por IA Guardián 🦉     │
│                                     │
└─────────────────────────────────────┘
```

### **Dashboard:**
```
┌─────────────────────────────────────┐
│ ← Bienvenido,      👤 🛡️            │
│   Jorge Pino                        │
├─────────────────────────────────────┤
│                                     │
│   ┌───────────────────────────┐   │
│   │ Saldo Disponible          │   │
│   │ S/ 15,432.75              │   │
│   │ •••• 9010                 │   │
│   └───────────────────────────┘   │
│                                     │
│   Acciones Rápidas                  │
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐             │
│   │💸│ │💳│ │🧾│ │🛡️│             │
│   └──┘ └──┘ └──┘ └──┘             │
│   Trans Pagar Card Segur            │
│                                     │
│   Actividad Reciente       Ver todo │
│   ┌───────────────────────────┐   │
│   │ 🎵 Spotify    -S/ 15.90   │   │
│   │    Nov 10                 │   │
│   └───────────────────────────┘   │
│   ┌───────────────────────────┐   │
│   │ 💼 Salary     +S/ 3,500   │   │
│   │    Nov 5                  │   │
│   └───────────────────────────┘   │
│                                     │
│                        🦉           │
└─────────────────────────────────────┘
```

### **Transfer Screen:**
```
┌─────────────────────────────────────┐
│ ← Transferir                        │
├─────────────────────────────────────┤
│                                     │
│   Cuenta Origen                     │
│   ┌───────────────────────────┐   │
│   │ Cuenta Ahorros •••• 9010  ▼│   │
│   └───────────────────────────┘   │
│                                     │
│   Destinatario                      │
│   ┌───────────────────────────┐   │
│   │ •••• 4521                 │   │
│   └───────────────────────────┘   │
│                                     │
│   Monto                             │
│   ┌───────────────────────────┐   │
│   │ S/  5,850.00              │   │
│   └───────────────────────────┘   │
│                                     │
│   Concepto                          │
│   ┌───────────────────────────┐   │
│   │ Pago urgente              │   │
│   └───────────────────────────┘   │
│                                     │
│   ⚠️ AURA: Monto elevado            │
│      Destinatario no registrado     │
│                                     │
│   ┌───────────────────────────┐   │
│   │ Confirmar Transferencia    │   │
│   └───────────────────────────┘   │
│                                     │
│                        🦉           │
└─────────────────────────────────────┘
```

---

## 🎭 Animation Patterns

### **Slide In (Panel):**
```
Motion:
  initial={{ x: '100%' }}
  animate={{ x: 0 }}
  exit={{ x: '100%' }}
  transition={{ 
    type: 'spring',
    damping: 25,
    stiffness: 300
  }}
```

### **Fade + Scale (Card):**
```
Motion:
  initial={{ opacity: 0, scale: 0.9 }}
  animate={{ opacity: 1, scale: 1 }}
  transition={{ duration: 0.3 }}
```

### **Pulse (Alert):**
```
Motion:
  animate={{
    scale: [1, 1.1, 1],
    opacity: [1, 0.8, 1]
  }}
  transition={{
    duration: 2,
    repeat: Infinity
  }}
```

### **Slide Up (Chat):**
```
Motion:
  initial={{ y: '100%' }}
  animate={{ y: 0 }}
  exit={{ y: '100%' }}
  transition={{ type: 'spring' }}
```

---

## 📏 Spacing System

```
Padding:
• Screen edges: 24px
• Card internal: 20px
• Button internal: 16px (vertical), 24px (horizontal)
• Small components: 12px

Gaps:
• Between cards: 16px
• Between sections: 24px
• Grid gaps: 12-16px
• Button groups: 12px

Border Radius:
• Cards: 16-24px
• Buttons: 12-16px
• Inputs: 12px
• Modals: 20px
```

---

## 🔤 Typography (No Custom Classes)

```
Uses default styles from globals.css

Headers:
• h1: ~28px (natural sizing)
• h2: ~24px
• h3: ~20px

Body:
• p: ~16px
• small: ~14px
• xs: ~12px

No Tailwind classes for:
• font-size
• font-weight
• line-height

These are controlled by globals.css
```

---

## ✨ Interactive States

### **Button Hover:**
```
Before: Background solid
Hover: Background +10% brightness
Active: Scale 0.95
```

### **Card Hover:**
```
Before: Shadow subtle
Hover: Shadow elevated
Active: Background +5% brightness
```

### **Input Focus:**
```
Before: Border gray
Focus: Border #0033CC
       Shadow cyan glow
```

---

## 🎨 Summary

This visual guide provides the complete design system for **Banco Seguro IA**:

✅ Layout structure (390×844 px)
✅ Color palette (primary, status, dark mode)
✅ AURA icon states (5 variations)
✅ Component patterns (cards, buttons, inputs)
✅ Screen templates (login, dashboard, transfer)
✅ Animation patterns (slide, fade, pulse)
✅ Spacing system (padding, gaps, radius)
✅ Typography guidelines
✅ Interactive states

All components follow the **"Invisible Security"** philosophy with modern glassmorphism, smooth animations, and intuitive interactions.

*Ready for implementation and consistent across all 26 screens.* ✨
