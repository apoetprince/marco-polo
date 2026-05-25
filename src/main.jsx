import React, { useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  Bell,
  CalendarClock,
  Camera,
  CirclePlus,
  Copy,
  HeartPulse,
  MapPin,
  MessageCircle,
  Phone,
  Radar,
  Save,
  Send,
  ShieldCheck,
  Stethoscope,
  UserRoundCog,
  X,
} from "lucide-react";
import "./styles.css";

const initialPhoto = "";

const baseCategories = [
  {
    id: "health",
    label: "Salud",
    accent: "#ff5f5f",
    icon: "pulse",
    notes: [],
  },
  {
    id: "food",
    label: "Alimentacion",
    accent: "#ffc857",
    icon: "bowl",
    notes: [],
  },
  {
    id: "medicine",
    label: "Medicina",
    accent: "#6ee7f9",
    icon: "capsule",
    notes: [],
  },
];

const timeline = [];

const responsibilityOptions = [
  "alimentacion",
  "refugio temporal",
  "medicacion",
  "emergencia",
  "transporte",
  "seguimiento",
];

const activeResponsibles = [
  { name: "Wyatt", role: "alimentacion" },
  { name: "Marta", role: "medicacion" },
  { name: "Carlos", role: "transporte" },
];

function CategorySvg({ type, color }) {
  return (
    <svg viewBox="0 0 64 64" aria-hidden="true" className="category-svg">
      <circle cx="32" cy="32" r="27" fill="rgba(255,255,255,.03)" stroke={color} strokeWidth="1.5" />
      {type === "pulse" && <path d="M14 34h9l4-12 8 24 5-13h10" fill="none" stroke={color} strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" />}
      {type === "bowl" && (
        <>
          <path d="M17 34h30c-1 10-7 15-15 15s-14-5-15-15Z" fill="none" stroke={color} strokeWidth="3" />
          <path d="M22 27c3-5 7-7 12-7 6 0 10 3 11 8" fill="none" stroke={color} strokeWidth="3" strokeLinecap="round" />
        </>
      )}
      {type === "capsule" && (
        <g transform="rotate(-28 32 32)">
          <rect x="18" y="25" width="28" height="14" rx="7" fill="none" stroke={color} strokeWidth="3" />
          <path d="M32 25v14" stroke={color} strokeWidth="3" />
        </g>
      )}
      {type === "orbit" && (
        <>
          <ellipse cx="32" cy="32" rx="22" ry="8" fill="none" stroke={color} strokeWidth="2.5" transform="rotate(-22 32 32)" />
          <ellipse cx="32" cy="32" rx="22" ry="8" fill="none" stroke={color} strokeWidth="2.5" transform="rotate(48 32 32)" />
          <circle cx="32" cy="32" r="4" fill={color} />
        </>
      )}
    </svg>
  );
}

function OwlSignal({ onClick }) {
  return (
    <button className="logo-button" onClick={onClick} aria-label="Editar perfil">
      <img className="logo-mark" src="/assets/marco-polo-tag-logo.png" alt="Marco Polo" />
    </button>
  );
}

function App() {
  const [loggedIn, setLoggedIn] = useState(false);
  const [authStep, setAuthStep] = useState("welcome");
  const [accountPath, setAccountPath] = useState("pet-first");
  const [tutorName, setTutorName] = useState("");
  const [email, setEmail] = useState("");
  const [petName, setPetName] = useState("Nuevo perfil");
  const [profileType, setProfileType] = useState("Mascota privada");
  const [communityStatus, setCommunityStatus] = useState("Privado");
  const [petPhoto, setPetPhoto] = useState(initialPhoto);
  const [categories, setCategories] = useState(baseCategories);
  const [activeId, setActiveId] = useState("health");
  const [note, setNote] = useState("");
  const [categoryName, setCategoryName] = useState("");
  const [profileOpen, setProfileOpen] = useState(false);
  const [responsibilityOpen, setResponsibilityOpen] = useState(false);
  const [nfcLink, setNfcLink] = useState("/p/peyton-a7f3");
  const [alertMode, setAlertMode] = useState(false);

  const activeCategory = useMemo(
    () => categories.find((category) => category.id === activeId) || categories[0],
    [activeId, categories]
  );

  const handlePhoto = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    setPetPhoto(URL.createObjectURL(file));
  };

  const addCategory = () => {
    const label = categoryName.trim();
    if (!label) return;
    const next = {
      id: `${label.toLowerCase().replaceAll(" ", "-")}-${Date.now()}`,
      label,
      accent: ["#34d399", "#a78bfa", "#ff9f43", "#6ee7f9"][categories.length % 4],
      icon: "orbit",
      notes: [],
    };
    setCategories((current) => [...current, next]);
    setActiveId(next.id);
    setCategoryName("");
  };

  const saveNote = (withAlert = false) => {
    const body = note.trim();
    if (!body) return;
    const prefix = withAlert ? "Alerta: " : "";
    setCategories((current) =>
      current.map((category) =>
        category.id === activeId ? { ...category, notes: [`${prefix}${body}`, ...category.notes] } : category
      )
    );
    setNote("");
    setAlertMode(false);
  };

  const generateNfcLink = () => {
    const slug = petName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "mascota";
    setNfcLink(`/p/${slug}-${Math.random().toString(16).slice(2, 6)}`);
  };

  if (!loggedIn) {
    return (
      <main className="login-shell">
        <section className="login-card">
          <OwlSignal onClick={() => setProfileOpen(true)} />
          {authStep === "welcome" && (
            <>
              <p className="eyebrow">Entrar a Marco Polo</p>
              <h1>Marco Polo</h1>
              <p className="brand-copy">Identidad, cuidado y seguimiento.</p>
              <div className="auth-actions">
                <button className="primary-action full" onClick={() => setAuthStep("intent")}>Crear cuenta</button>
                <button className="ghost-action full" onClick={() => setAuthStep("login")}>Ya tengo cuenta</button>
                <button className="ghost-action full" onClick={() => setAuthStep("admin")}>Entrada administrador</button>
              </div>
            </>
          )}

          {authStep === "admin" && (
            <>
              <p className="eyebrow">Entrada administrador</p>
              <h2>Marco Polo</h2>
              <p className="brand-copy">Acceso para administrar perfiles, casos, servicios y permisos.</p>
              <input placeholder="Correo administrador" />
              <input placeholder="Contraseña" type="password" />
              <button className="primary-action full" onClick={() => setLoggedIn(true)}>Entrar</button>
              <button className="ghost-action full" onClick={() => setAuthStep("recover")}>Recuperar contraseña</button>
              <button className="ghost-action full" onClick={() => setAuthStep("welcome")}>Volver</button>
            </>
          )}

          {authStep === "login" && (
            <>
              <p className="eyebrow">Volver a entrar</p>
              <h2>Marco Polo</h2>
              <p className="brand-copy">Accede con tu cuenta para ver tus mascotas, casos o pacientes.</p>
              <input value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Correo electronico" />
              <input placeholder="Contraseña" type="password" />
              <button className="primary-action full" onClick={() => setLoggedIn(true)}>Entrar</button>
              <button className="ghost-action full" onClick={() => setAuthStep("recover")}>Recuperar contraseña</button>
              <button className="ghost-action full" onClick={() => setAuthStep("welcome")}>Volver</button>
            </>
          )}

          {authStep === "intent" && (
            <>
              <p className="eyebrow">Antes de empezar</p>
              <h2>¿Cómo quieres crear tu espacio?</h2>
              <div className="intent-grid">
                <button
                  className={`intent-card ${accountPath === "pet-first" ? "is-selected" : ""}`}
                  onClick={() => setAccountPath("pet-first")}
                >
                  <strong>Empezar por la mascota</strong>
                  <span>Creas el perfil o caso primero y luego agregas tutor, responsables o comunidad.</span>
                </button>
                <button
                  className={`intent-card ${accountPath === "tutor-first" ? "is-selected" : ""}`}
                  onClick={() => setAccountPath("tutor-first")}
                >
                  <strong>Empezar como tutor</strong>
                  <span>Creas tu cuenta y luego agregas varias mascotas con varios tutores.</span>
                </button>
                <button
                  className={`intent-card ${accountPath === "vet" ? "is-selected" : ""}`}
                  onClick={() => {
                    setAccountPath("vet");
                    setProfileType("Caso veterinario");
                  }}
                >
                  <strong>Soy veterinario</strong>
                  <span>Separa tus propias mascotas de los pacientes que llevas.</span>
                </button>
              </div>
              <button className="primary-action full" onClick={() => setAuthStep("account")}>Continuar</button>
            </>
          )}

          {authStep === "account" && (
            <>
              <p className="eyebrow">Paso 1 de 3</p>
              <h2>Marco Polo</h2>
              <p className="brand-copy">
                {accountPath === "pet-first" && "Pet ID primero. Despues agregas tutor o responsables."}
                {accountPath === "tutor-first" && "Tutor primero. Despues agregas una o varias mascotas."}
                {accountPath === "vet" && "Cuenta veterinaria con mascotas propias y pacientes."}
              </p>
              <input value={tutorName} onChange={(event) => setTutorName(event.target.value)} placeholder="Tu nombre" />
              <input value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Correo electronico" />
              <input placeholder="Crear contraseña" type="password" />
              <button className="primary-action full" onClick={() => setAuthStep("profile")}>Continuar</button>
              <button className="ghost-action full" onClick={() => setAuthStep("recover")}>Recuperar contraseña</button>
            </>
          )}

          {authStep === "recover" && (
            <>
              <p className="eyebrow">Recuperar acceso</p>
              <h2>Marco Polo</h2>
              <p className="brand-copy">Escribe tu correo y te enviaremos un enlace para volver a entrar.</p>
              <input value={email} onChange={(event) => setEmail(event.target.value)} placeholder="Correo electronico" />
              <button className="primary-action full" onClick={() => setAuthStep("welcome")}>Enviar enlace</button>
              <button className="ghost-action full" onClick={() => setAuthStep("welcome")}>Volver</button>
            </>
          )}

          {authStep === "profile" && (
            <>
              <p className="eyebrow">Paso 2 de 3</p>
              <h2>Tipo de perfil</h2>
              <div className="choice-grid">
                {["Mascota privada", "Mascota comunitaria", "Rescate temporal", "Caso veterinario"].map((type) => (
                  <button
                    className={`ghost-action ${profileType === type ? "is-selected" : ""}`}
                    key={type}
                    onClick={() => setProfileType(type)}
                  >
                    {type}
                  </button>
                ))}
              </div>
              <button className="primary-action full" onClick={() => setAuthStep("pet")}>Continuar</button>
            </>
          )}

          {authStep === "pet" && (
            <>
              <p className="eyebrow">Paso 3 de 3</p>
              <h2>¿Cómo se llama?</h2>
              <input value={petName === "Nuevo perfil" ? "" : petName} onChange={(event) => setPetName(event.target.value || "Nuevo perfil")} placeholder="Ej. Negro, Chai, Luna, Caso zona 1..." />
              <label className="upload-line">
                <Camera size={17} />
                Subir foto
                <input type="file" accept="image/*" onChange={handlePhoto} />
              </label>
              <button className="primary-action full" onClick={() => setLoggedIn(true)}>Crear espacio</button>
            </>
          )}
        </section>
      </main>
    );
  }

  return (
    <main className="app-shell">
      <section className="hero-band">
        <div className="brand-lockup">
          <OwlSignal onClick={() => setProfileOpen(true)} />
          <div>
            <p className="eyebrow">Identidad, cuidado y seguimiento</p>
            <h1>Marco Polo</h1>
            <p className="brand-copy">Toca el simbolo para editar el perfil de {petName}.</p>
          </div>
        </div>
        <div className="status-strip">
          <span><Radar size={16} /> Vinculo publico</span>
          <span><ShieldCheck size={16} /> Perfil seguro</span>
          <span><CalendarClock size={16} /> Diario</span>
        </div>
      </section>

      <section className="dashboard-grid">
        <aside className="pet-console">
          <label className="pet-orbit">
            <input type="file" accept="image/*" onChange={handlePhoto} />
            <div className="pet-photo">
              <img src={petPhoto} alt={petName} />
            </div>
            <span className="photo-hint"><Camera size={16} /> Cambiar foto</span>
          </label>
          <p className="eyebrow">Companero central</p>
          <h2>{petName}</h2>
          <p className="pet-meta">{profileType} · {communityStatus} · Guatemala</p>
          <div className="critical-card">
            <HeartPulse size={18} />
            <div>
              <strong>Diario</strong>
              <span className="example-text">Ej. ¿Qué pasó hoy? Agrega una nota, síntoma, cuidado o seguimiento.</span>
            </div>
          </div>
          <button className="primary-action"><MessageCircle size={18} /> Buzon de mensajes</button>
          <div className="quick-actions">
            <button className="ghost-action"><Phone size={17} /> Directorio de emergencia</button>
            <button className="ghost-action"><MessageCircle size={17} /> Chat y contactos</button>
            <button className="ghost-action" onClick={() => setResponsibilityOpen(true)}><CirclePlus size={17} /> Tareas nuevas</button>
          </div>
        </aside>

        <section className="care-console">
          <div className="quick-note">
            <div>
              <p className="eyebrow">Nota libre en {activeCategory.label}</p>
              <h2>¿Qué pasó hoy?</h2>
            </div>
            <textarea
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder={activeId === "health" ? "Ej. Doctor, contacto, tratamiento, sintomas o algo que deba recordarse." : "Escribe libremente. Marco Polo lo convierte en diario."}
              rows={4}
            />
            {alertMode && <input className="soft-input" placeholder="Horario opcional: hoy 8:00 p.m., cada 12 horas..." />}
            <div className="note-actions">
              <button className="ghost-action" onClick={() => setAlertMode((value) => !value)}><Bell size={17} /> Agregar alerta</button>
              <button className="send-action" onClick={() => saveNote(alertMode)}><Save size={17} /> Guardar</button>
            </div>
          </div>

          <div className="community-panel">
            <div>
              <p className="eyebrow">Custodia comunitaria</p>
              <h2>Todos vemos por el</h2>
              <p>Cuando no hay un tutor formal, el perfil funciona como una red alrededor del caso.</p>
            </div>
            <div className="responsible-list">
              <span className="example-text">Ej. Ana · alimentacion</span>
              <span className="example-text">Ej. Vet aliada</span>
              <span className="example-text">Ej. Transporte</span>
            </div>
          </div>

          <div className="add-category">
            <input value={categoryName} onChange={(event) => setCategoryName(event.target.value)} placeholder="Agregar categoria: groomer, paseos, alergias..." />
            <button className="primary-action" onClick={addCategory}><CirclePlus size={18} /> Agregar</button>
          </div>

          <div className="category-dock">
            {categories.map((category) => (
              <button
                className={`category-tile ${activeId === category.id ? "is-active" : ""}`}
                key={category.id}
                onClick={() => setActiveId(category.id)}
                style={{ "--tile-accent": category.accent }}
              >
                <CategorySvg type={category.icon} color={category.accent} />
                <span>{category.label}</span>
              </button>
            ))}
          </div>

          <div className="detail-panel" style={{ "--panel-accent": activeCategory.accent }}>
            <div className="panel-heading">
              <CategorySvg type={activeCategory.icon} color={activeCategory.accent} />
              <div>
                <p className="eyebrow">Contenido de {activeCategory.label}</p>
                <h2>{activeCategory.label}</h2>
                <p>{activeId === "health" ? "Aqui vive el doctor, contacto, tratamiento y cualquier observacion de salud." : "Notas libres guardadas por la familia."}</p>
              </div>
            </div>
            <div className="entry-list">
              {activeCategory.notes.length ? activeCategory.notes.map((entry) => (
                <article key={entry} className="entry-row"><span>{entry}</span></article>
              )) : <article className="empty-state">Ej. {activeId === "health" ? "Doctor, contacto, tratamiento, sintomas o seguimiento." : "Una observacion libre que quieras guardar aqui."}</article>}
            </div>
          </div>
        </section>

        <aside className="signal-panel">
          <div className="public-card">
            <p className="eyebrow">Perfil publico</p>
            <h2>{nfcLink}</h2>
            <p>Este vinculo abre la vista publica del perfil.</p>
            <button className="ghost-action full" onClick={generateNfcLink}><Radar size={17} /> Generar vinculo</button>
            <button className="ghost-action full"><Copy size={17} /> Copiar vinculo</button>
            <button className="ghost-action full"><MapPin size={17} /> Vista publica</button>
          </div>
          <div className="timeline-card">
            <p className="eyebrow">Ultimas entradas</p>
            {timeline.length ? timeline.map((item) => (
              <div className="timeline-item" key={item.time}>
                <span>{item.time}</span>
                <p>{item.text}</p>
              </div>
            )) : <div className="empty-state">Aun no hay entradas. Escribe en el diario para empezar el historial.</div>}
          </div>
          <button className="primary-action full"><Send size={18} /> Avisar a veterinaria</button>
        </aside>
      </section>

      {profileOpen && (
        <div className="modal-backdrop" onClick={() => setProfileOpen(false)}>
          <section className="profile-modal" onClick={(event) => event.stopPropagation()}>
            <button className="close-button" onClick={() => setProfileOpen(false)}><X size={18} /></button>
            <UserRoundCog size={28} />
            <p className="eyebrow">Editar perfil</p>
            <h2>Datos principales</h2>
            <input value={petName} onChange={(event) => setPetName(event.target.value)} />
            <select value={profileType} onChange={(event) => setProfileType(event.target.value)}>
              <option>Mascota privada</option>
              <option>Mascota comunitaria</option>
              <option>Rescate temporal</option>
              <option>Caso veterinario</option>
            </select>
            <select value={communityStatus} onChange={(event) => setCommunityStatus(event.target.value)}>
              <option>Privado</option>
              <option>Comunitario</option>
              <option>Rescate activo</option>
              <option>Emergencia</option>
            </select>
            <textarea defaultValue="Alergia leve. Si se encuentra solo, contactar al tutor antes de alimentarlo." rows={4} />
            <button className="primary-action full" onClick={() => setProfileOpen(false)}>Guardar perfil</button>
          </section>
        </div>
      )}

      {responsibilityOpen && (
        <div className="modal-backdrop" onClick={() => setResponsibilityOpen(false)}>
          <section className="profile-modal" onClick={(event) => event.stopPropagation()}>
            <button className="close-button" onClick={() => setResponsibilityOpen(false)}><X size={18} /></button>
            <p className="eyebrow">Tareas nuevas</p>
            <h2>¿Qué hay que hacer?</h2>
            <div className="choice-grid">
              {responsibilityOptions.map((option) => (
                <button className="ghost-action" key={option}>{option}</button>
              ))}
            </div>
            <textarea placeholder="Contacto o nota breve para coordinar." rows={3} />
            <button className="primary-action full" onClick={() => setResponsibilityOpen(false)}>Agregar tarea</button>
          </section>
        </div>
      )}
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
