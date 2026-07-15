import React from 'react';
import { motion } from 'framer-motion';

import logoFull from './assets/PlantyLink.png';
import logoIcon from './assets/PlantyLink logo.png';
import screenshotDash from './assets/Screenshot_20260714_144219[1].png';
import screenshotProfile from './assets/Screenshot_20260714_144243[1].png';
import screenshotHistory from './assets/Screenshot_20260714_144258[1].png';

// Utilidad para animaciones recurrentes
const fadeInUp = {
  hidden: { opacity: 0, y: 40 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: "easeOut" } }
};

function App() {
  return (
    <div className="min-h-screen bg-white text-gray-800 font-sans selection:bg-planty-light selection:text-planty-dark overflow-x-hidden">

      {/* Navegación */}
      <nav className="fixed w-full bg-white/80 backdrop-blur-md border-b border-gray-100 z-50 transition-all duration-300">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <a href="#" className="flex items-center">
              <img src={logoFull} alt="PlantyLink" className="h-8" />
            </a>
            <div className="hidden md:flex space-x-8">
              <a href="#beneficios" className="text-gray-600 hover:text-planty transition font-medium">Beneficios</a>
              <a href="#como-funciona" className="text-gray-600 hover:text-planty transition font-medium">Cómo funciona</a>
              <a href="#app" className="text-gray-600 hover:text-planty transition font-medium">La App</a>
              <a href="#equipo" className="text-gray-600 hover:text-planty transition font-medium">Equipo</a>
            </div>
            <a href="#descarga" className="bg-planty hover:bg-planty-dark text-white px-5 py-2 rounded-full font-medium transition shadow-md hover:shadow-lg">
              Descargar App
            </a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-24 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <motion.div 
              initial="hidden" 
              animate="visible" 
              variants={fadeInUp} 
              className="text-center lg:text-left"
            >
              <span className="inline-block py-1 px-3 rounded-full bg-planty-light text-planty text-sm font-bold mb-6 tracking-wide">
                VERSIÓN 1.0 DISPONIBLE
              </span>
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-extrabold tracking-tight text-gray-900 mb-6">
                Dale voz a tus <span className="text-transparent bg-clip-text bg-gradient-to-r from-planty to-emerald-400">plantas.</span>
              </h1>
              <p className="text-lg text-gray-600 mb-8 max-w-2xl mx-auto lg:mx-0">
                Monitoreo inteligente en tiempo real. Conecta sensores y recibe datos precisos sobre humedad y temperatura directamente en tu celular. Cuida tus plantas como nunca antes.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                <a href="#descarga" className="bg-planty hover:bg-planty-dark text-white px-8 py-3 rounded-full font-semibold text-lg transition shadow-lg hover:-translate-y-1">
                  Descargar APK
                </a>
                <a href="https://github.com/dnbravo04/PlantyLink" target="_blank" rel="noreferrer" className="bg-white border border-gray-200 text-gray-700 hover:bg-gray-50 hover:border-gray-300 px-8 py-3 rounded-full font-semibold text-lg transition">
                  Ver en GitHub
                </a>
              </div>
            </motion.div>

            {/* Visual Header */}
            <motion.div 
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.8 }}
              className="relative mt-10 lg:mt-0 flex justify-center"
            >
              <div className="absolute inset-0 bg-planty-light rounded-full blur-3xl opacity-60"></div>
              <motion.img
                animate={{ y: [0, -15, 0] }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                src={logoIcon}
                alt="Icono PlantyLink"
                className="relative z-10 w-48 md:w-64 h-auto drop-shadow-2xl"
              />
            </motion.div>
          </div>
        </div>
      </section>

      {/* Propósito */}
      <section id="proposito" className="py-16 bg-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <motion.div 
            initial="hidden" whileInView="visible" viewport={{ once: true, margin: "-50px" }} variants={fadeInUp}
            className="bg-planty-light/50 border border-planty/20 rounded-3xl p-8 md:p-12"
          >
            <p className="text-lg md:text-xl text-gray-600 leading-relaxed mb-4 italic">
              Creado para responder una pregunta real:
            </p>
            <p className="text-2xl md:text-3xl font-bold text-planty leading-snug">
              ¿Y si pudieras saber exactamente lo que tu planta necesita, antes de que sea demasiado tarde?
            </p>
          </motion.div>
        </div>
      </section>

      {/* Números / Impacto */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            {[
              { number: '24/7', label: 'Monitoreo continuo' },
              { number: '< 1 min', label: 'Vinculación instantánea' },
              { number: '100%', label: 'Datos en la nube' },
              { number: '+1000', label: 'Especies en catálogo' },
            ].map((stat, idx) => (
              <motion.div 
                key={idx} 
                initial={{ opacity: 0, scale: 0.8 }} whileInView={{ opacity: 1, scale: 1 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.1, duration: 0.5 }}
                className="p-6"
              >
                <p className="text-3xl md:text-4xl font-extrabold text-planty mb-2">{stat.number}</p>
                <p className="text-gray-600 font-medium">{stat.label}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Beneficios */}
      <section id="beneficios" className="py-24 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Todo lo que tus plantas necesitan, en tu bolsillo</h2>
            <p className="text-lg text-gray-600">Olvida las adivinanzas. PlantyLink te da información precisa y oportuna para que tus plantas siempre estén en las mejores condiciones.</p>
          </motion.div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              { icon: '📊', title: 'Datos en tiempo real', desc: 'Humedad del suelo, humedad ambiental y temperatura actualizados constantemente.' },
              { icon: '⚡', title: 'Vinculación instantánea', desc: 'Acerca tu celular al sensor y vincúlalo al instante. Sin configuraciones complicadas.' },
              { icon: '🌿', title: 'Catálogo botánico', desc: 'Más de 1,000 especies con rangos ideales de cuidado para tu planta específica.' },
              { icon: '🔔', title: 'Alertas inteligentes', desc: 'Recibe notificaciones cuando tu planta necesita agua o detectamos un cambio brusco.' },
            ].map((feature, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.15, duration: 0.5 }}
                className="bg-white p-8 rounded-3xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-2 transition duration-300"
              >
                <div className="text-4xl bg-planty-light w-16 h-16 rounded-2xl flex items-center justify-center mb-6">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                <p className="text-gray-600">{feature.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Cómo Funciona */}
      <section id="como-funciona" className="py-24 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Tan fácil como 1, 2, 3</h2>
            <p className="text-lg text-gray-600">Empieza a monitorear tus plantas en minutos, sin ser experto en tecnología.</p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              { step: '1', title: 'Conecta el sensor', desc: 'Coloca el sensor PlantyLink cerca de tu planta. Se alimenta de manera sencilla y empieza a captar datos al instante.', icon: '🔌' },
              { step: '2', title: 'Vincula con tu celular', desc: 'Abre la app, acerca tu teléfono al sensor y listo. La vinculación es automática, sin códigos ni configuraciones.', icon: '📱' },
              { step: '3', title: 'Monitorea y alertas', desc: 'Visualiza los datos de tus plantas en tiempo real y recibe notificaciones cuando necesiten atención.', icon: '🌱' },
            ].map((item, idx) => (
              <motion.div 
                key={idx} 
                initial={{ opacity: 0, x: -30 }} whileInView={{ opacity: 1, x: 0 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.2, duration: 0.5 }}
                className="relative text-center p-8"
              >
                <div className="text-5xl mb-6">{item.icon}</div>
                <div className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-planty text-white font-bold text-lg mb-4 shadow-lg shadow-planty/30">
                  {item.step}
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{item.title}</h3>
                <p className="text-gray-600">{item.desc}</p>
                {idx < 2 && (
                  <div className="hidden md:block absolute top-16 -right-4 text-planty/30 text-4xl font-bold">
                    →
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Para quién es */}
      <section className="py-24 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">¿Para quién es PlantyLink?</h2>
            <p className="text-lg text-gray-600">Ya seas principiante o experto, PlantyLink se adapta a ti.</p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              { icon: '🏠', title: 'Amantes de las plantas', desc: 'Nunca más te preguntes si regaste de más o de menos. PlantyLink te dice exactamente qué necesita cada planta.' },
              { icon: '👨‍🌾', title: 'Agricultores y huerteros', desc: 'Optimiza el riego y las condiciones de tus cultivos con datos precisos. Ahorra agua y mejora tus cosechas.' },
              { icon: '🎓', title: 'Estudiantes e investigadores', desc: 'Herramienta perfecta para proyectos de botánica, agronomía o IoT. Totalmente documentada y fácil de integrar.' },
            ].map((item, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, scale: 0.9 }} whileInView={{ opacity: 1, scale: 1 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.15, duration: 0.5 }}
                className="bg-white p-8 rounded-3xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-2 transition duration-300 text-center"
              >
                <div className="text-5xl mb-6">{item.icon}</div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{item.title}</h3>
                <p className="text-gray-600">{item.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Interfaz / Showcase */}
      <section id="app" className="py-24 overflow-hidden relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <motion.div 
              initial={{ opacity: 0, x: -50 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ duration: 0.8 }}
              className="order-2 lg:order-1 relative flex justify-center lg:justify-end pr-0 lg:pr-10"
            >
              <div className="relative w-full max-w-md h-[600px] flex items-center justify-center group">
                <img src={screenshotDash} alt="Dashboard" className="absolute left-0 w-48 md:w-56 rounded-[2rem] shadow-2xl border-[6px] border-white -rotate-6 scale-90 z-10 group-hover:z-30 group-hover:scale-100 transition-all duration-500 ease-out" />
                <img src={screenshotHistory} alt="Historial" className="absolute right-0 w-48 md:w-56 rounded-[2rem] shadow-2xl border-[6px] border-white rotate-6 scale-90 z-10 group-hover:z-30 group-hover:scale-100 transition-all duration-500 ease-out" />
                <img src={screenshotProfile} alt="Perfil" className="absolute z-20 w-56 md:w-64 rounded-[2rem] shadow-2xl border-[6px] border-white translate-y-12 group-hover:-translate-y-2 transition-all duration-500 ease-out" />
              </div>
            </motion.div>
            
            <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="order-1 lg:order-2 text-center lg:text-left">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-6">Una app diseñada para ti, no para ingenieros</h2>
              <p className="text-lg text-gray-600 mb-8">
                Interfaz limpia y fácil de usar. Visualiza el estado de todas tus plantas de un vistazo, consulta el historial y personaliza tu perfil. Incluye modo demo para que la explores antes de tener el sensor.
              </p>
              <ul className="space-y-4 text-left inline-block lg:block">
                {[
                  'Dashboard claro con el estado de cada planta',
                  'Historial de lecturas con gráficas intuitivas',
                  'Modo oscuro nativo para cuidar tus ojos',
                  'Modo demo: prueba la app sin hardware'
                ].map((text, i) => (
                  <motion.li 
                    key={i} initial={{ opacity: 0, x: 20 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }} transition={{ delay: i * 0.15 }}
                    className="flex items-center text-gray-700 font-medium"
                  >
                    <span className="text-planty mr-3 text-xl">✓</span> {text}
                  </motion.li>
                ))}
              </ul>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Equipo */}
      <section id="equipo" className="py-24 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Conoce al equipo</h2>
            <p className="text-lg text-gray-600">Somos el PlantyLink Team: un equipo apasionado por la tecnología y el cuidado del medio ambiente.</p>
          </motion.div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {[
              { name: 'Emmanuel Dueñas', role: 'Investigación & Diseño' },
              { name: 'Luis Medina', role: 'Investigación & Diseño' },
              { name: 'Michelle Vanegas', role: 'Desarrollo & Hardware' },
              { name: 'Diego Bravo', role: 'Desarrollo & Arquitectura' },
            ].map((member, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, y: 30 }} whileInView={{ opacity: 1, y: 0 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.1, duration: 0.5 }}
                className="text-center p-6 bg-white rounded-3xl shadow-sm border border-gray-100 hover:shadow-lg transition duration-300"
              >
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-planty to-emerald-400 mx-auto mb-4 flex items-center justify-center shadow-inner">
                  <span className="text-white text-2xl font-bold">
                    {member.name.split(' ').map(n => n[0]).join('')}
                  </span>
                </div>
                <h3 className="font-bold text-gray-900 text-lg">{member.name}</h3>
                <p className="text-gray-500 text-sm mt-1">{member.role}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Preguntas Frecuentes */}
      <section className="py-24 bg-white">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp} className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Preguntas frecuentes</h2>
          </motion.div>

          <div className="space-y-4">
            {[
              { q: '¿Cuánto cuesta PlantyLink?', a: 'PlantyLink ofrece una versión inicial gratuita para que explores sus funcionalidades. Próximamente lanzaremos planes con características premium para quienes quieran llevar el cuidado de sus plantas al siguiente nivel.' },
              { q: '¿Necesito el sensor para usar la app?', a: 'No necesariamente. La app incluye un modo demo que te permite explorar todas las funcionalidades sin necesidad de hardware.' },
              { q: '¿Qué datos mide el sensor?', a: 'El sensor mide humedad del suelo, humedad ambiental y temperatura. Estos datos se envían a tu celular en tiempo real.' },
              { q: '¿Es compatible con mi celular?', a: 'PlantyLink está disponible para Android 5.0 o superior. Estamos trabajando para traer compatibilidad con iOS en el futuro.' },
              { q: '¿Puedo monitorear varias plantas a la vez?', a: 'Sí, puedes vincular múltiples sensores y monitorear todas tus plantas desde un solo dashboard.' },
            ].map((faq, idx) => (
              <motion.div 
                key={idx}
                initial={{ opacity: 0, x: -20 }} whileInView={{ opacity: 1, x: 0 }} 
                viewport={{ once: true }} transition={{ delay: idx * 0.1, duration: 0.4 }}
                className="bg-gray-50 rounded-2xl p-6 border border-gray-100 hover:border-planty/30 transition-colors"
              >
                <h3 className="font-bold text-gray-900 text-lg mb-2">{faq.q}</h3>
                <p className="text-gray-600">{faq.a}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Descarga */}
      <section id="descarga" className="relative py-24">
        <div className="absolute inset-0 bg-gray-900"></div>
        <div className="relative max-w-4xl mx-auto px-4 text-center z-10 text-white">
          <motion.div initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeInUp}>
            <h2 className="text-4xl md:text-5xl font-bold mb-6">Empieza a monitorear hoy</h2>
            <p className="text-xl text-gray-300 mb-10 max-w-2xl mx-auto">
              Únete a la nueva generación de cuidado de plantas. Descarga la app y empieza hoy.
            </p>
            <div className="bg-white/10 backdrop-blur-md border border-white/20 p-8 rounded-3xl max-w-md mx-auto">
              <p className="text-planty-light font-semibold mb-4">Versión actual: v1.0 (Julio 2026)</p>
              <a href="/downloads/plantylink-v1.0.apk" className="block w-full bg-planty hover:bg-planty-dark text-white py-4 rounded-xl font-bold text-lg transition mb-4 shadow-[0_0_20px_rgba(5,150,105,0.4)] hover:shadow-[0_0_30px_rgba(5,150,105,0.6)] hover:-translate-y-1">
                Descargar APK (Android)
              </a>
              <p className="text-sm text-gray-400">Requiere Android 5.0 (API 21) o superior</p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-50 border-t border-gray-200 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6 mb-8">
            <div className="flex items-center gap-3">
              <img src={logoIcon} alt="Logo" className="h-8 grayscale opacity-60" />
              <p className="text-gray-500 font-medium">PlantyLink</p>
            </div>
            <div className="flex gap-6">
              <a href="https://github.com/dnbravo04/PlantyLink" target="_blank" rel="noreferrer" className="text-gray-500 hover:text-planty font-medium transition">GitHub</a>
              <a href="mailto:dnbravo04@gmail.com" className="text-gray-500 hover:text-planty font-medium transition">Contacto</a>
            </div>
          </div>
          <div className="border-t border-gray-200 pt-8 text-center">
            <p className="text-gray-400 text-sm mb-2">
              Creado por el <span className="font-semibold text-gray-500">PlantyLink Team</span>: Emmanuel Dueñas, Luis Medina, Michelle Vanegas y Diego Bravo.
            </p>
            <p className="text-gray-400 text-sm">&copy; 2026 PlantyLink Team. Todos los derechos reservados.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;