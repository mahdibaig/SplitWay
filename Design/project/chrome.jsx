/* Splitway shared chrome — icons, tab bar, status bar, FAB, avatars, capybara */

// ───────── SF-Symbol-styled inline icon library ─────────
// Hand-tuned outlines mirroring SF Symbols at default weight.
// Pass {size, color, weight} props. Weight maps to stroke-width.

const SW = { regular: 1.7, medium: 2.0, semibold: 2.3 };
const Ic = (path, vb = '0 0 24 24') => ({ size = 22, color = 'currentColor', weight = 'regular', fill = false, style }) => (
  <svg width={size} height={size} viewBox={vb} fill="none"
       stroke={color} strokeWidth={SW[weight]} strokeLinecap="round" strokeLinejoin="round" style={style}>
    {fill ? React.cloneElement(path, { fill: color, stroke: 'none' }) : path}
  </svg>
);

const Icon = {
  // Tab bar
  house:        Ic(<><path d="M3 11l9-8 9 8" /><path d="M5 10v10h14V10" /><path d="M10 20v-6h4v6" /></>),
  receipt:      Ic(<><path d="M5 3v18l2-1.5L9 21l2-1.5L13 21l2-1.5L17 21l2-1.5V3l-2 1.5L15 3l-2 1.5L11 3 9 4.5 7 3 5 4.5z"/><path d="M8 9h8M8 13h8M8 17h5"/></>),
  chartPie:     Ic(<><path d="M12 3v9l8 4a9 9 0 1 1-8-13z"/></>),
  settings:     Ic(<><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></>),
  // Actions
  plus:         Ic(<><path d="M12 5v14M5 12h14"/></>),
  close:        Ic(<><path d="M6 6l12 12M6 18L18 6"/></>),
  chevronR:     Ic(<><path d="M9 6l6 6-6 6"/></>),
  chevronL:     Ic(<><path d="M15 6l-6 6 6 6"/></>),
  chevronD:     Ic(<><path d="M6 9l6 6 6-6"/></>),
  chevronU:     Ic(<><path d="M6 15l6-6 6 6"/></>),
  arrowUp:      Ic(<><path d="M12 19V5M5 12l7-7 7 7"/></>),
  arrowUpR:     Ic(<><path d="M7 17 17 7M9 7h8v8"/></>),
  arrowDownR:   Ic(<><path d="M7 7l10 10M17 9v8H9"/></>),
  check:        Ic(<><path d="M5 12l5 5L20 7"/></>),
  search:       Ic(<><circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/></>),
  camera:       Ic(<><path d="M3 8h3l2-3h8l2 3h3v11H3z"/><circle cx="12" cy="13" r="4"/></>),
  flash:        Ic(<><path d="M13 3 4 14h7v7l9-11h-7z"/></>),
  filter:       Ic(<><path d="M3 5h18M6 12h12M10 19h4"/></>),
  edit:         Ic(<><path d="M17 3 21 7 8 20H4v-4z"/></>),
  // Money / categories
  cart:         Ic(<><circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M3 4h2l3 12h11l2-8H7"/></>),
  fork:         Ic(<><path d="M7 2v8a3 3 0 0 0 6 0V2M10 10v12M17 2c-2 0-3 2-3 5s1 5 3 5v10"/></>),
  bolt:         Ic(<><path d="M13 3 4 14h7v7l9-11h-7z"/></>),
  car:          Ic(<><path d="M3 16v-3l2-6h14l2 6v3M3 16h18M3 16v3h3v-3M21 16v3h-3v-3"/><circle cx="7" cy="16" r="1"/><circle cx="17" cy="16" r="1"/></>),
  play:         Ic(<><polygon points="6,4 20,12 6,20"/></>),
  heart:        Ic(<><path d="M12 21s-8-5-8-11a5 5 0 0 1 9-3 5 5 0 0 1 9 3c0 6-8 11-10 11z"/></>),
  bag:          Ic(<><path d="M5 8h14l-1 12H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/></>),
  sparkle:      Ic(<><path d="M12 3v5M12 16v5M3 12h5M16 12h5M5.5 5.5l3.5 3.5M15 15l3.5 3.5M5.5 18.5 9 15M15 9l3.5-3.5"/></>),
  dots:         Ic(<><circle cx="6" cy="12" r="1.5" /><circle cx="12" cy="12" r="1.5" /><circle cx="18" cy="12" r="1.5" /></>),
  house2:       Ic(<><path d="M4 11l8-7 8 7v9h-5v-6h-6v6H4z"/></>),
  wallet:       Ic(<><path d="M3 7h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M3 7V6a2 2 0 0 1 2-2h12"/><circle cx="17" cy="14" r="1.3"/></>),
  bell:         Ic(<><path d="M6 9a6 6 0 1 1 12 0c0 4 2 5 2 7H4c0-2 2-3 2-7"/><path d="M10 20a2 2 0 0 0 4 0"/></>),
  // Misc
  calendar:     Ic(<><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 9h18M8 3v4M16 3v4"/></>),
  users:        Ic(<><circle cx="9" cy="9" r="3.5"/><path d="M2 20a7 7 0 0 1 14 0"/><circle cx="17" cy="8" r="2.5"/><path d="M16 14a5 5 0 0 1 6 5"/></>),
  user:         Ic(<><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></>),
  zelle:        Ic(<><rect x="3" y="3" width="18" height="18" rx="9"/><path d="M9 8h6l-6 8h6"/></>),
  link:         Ic(<><path d="M10 14a4 4 0 0 0 5.5 0l3-3a4 4 0 1 0-5.5-5.5l-1 1"/><path d="M14 10a4 4 0 0 0-5.5 0l-3 3a4 4 0 1 0 5.5 5.5l1-1"/></>),
  copy:         Ic(<><rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/></>),
  shield:       Ic(<><path d="M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z"/></>),
  toggle:       Ic(<><rect x="3" y="7" width="18" height="10" rx="5"/><circle cx="15" cy="12" r="3"/></>),
  trend:        Ic(<><path d="M3 17l5-5 4 4 8-9"/><path d="M14 7h6v6"/></>),
  q:            Ic(<><circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 4 3l-1 1v1M12 17h0"/></>),
  star:         Ic(<><polygon points="12,3 14.5,9 21,9.5 16,14 17.5,21 12,17 6.5,21 8,14 3,9.5 9.5,9"/></>),
  info:         Ic(<><circle cx="12" cy="12" r="9"/><path d="M12 8h0M11 12h1v5"/></>),
  // Signal/wifi/battery for status bar
  signal: (p={}) => (
    <svg width="18" height="11" viewBox="0 0 18 11" fill={p.color || 'currentColor'}>
      <rect x="0" y="7" width="3" height="4" rx="0.6"/><rect x="5" y="5" width="3" height="6" rx="0.6"/>
      <rect x="10" y="3" width="3" height="8" rx="0.6"/><rect x="15" y="0" width="3" height="11" rx="0.6"/>
    </svg>
  ),
  wifi: (p={}) => (
    <svg width="16" height="11" viewBox="0 0 16 11" fill={p.color || 'currentColor'}>
      <path d="M8 3.5c2.2 0 4.1.8 5.6 2.3l1.2-1.2A8.3 8.3 0 0 0 8 1.7 8.3 8.3 0 0 0 1.2 4.6l1.2 1.2C3.9 4.3 5.8 3.5 8 3.5z"/>
      <path d="M8 6.7c1.3 0 2.5.5 3.4 1.5l1.2-1.2A6 6 0 0 0 8 4.9 6 6 0 0 0 3.4 7l1.2 1.2C5.5 7.2 6.7 6.7 8 6.7z"/>
      <circle cx="8" cy="10" r="1.3"/>
    </svg>
  ),
  battery: (p={}) => (
    <svg width="25" height="12" viewBox="0 0 25 12" fill="none">
      <rect x="0.5" y="0.5" width="21" height="11" rx="3" stroke={p.color||'currentColor'} strokeOpacity="0.4"/>
      <rect x="2" y="2" width="18" height="8" rx="1.8" fill={p.color||'currentColor'}/>
      <path d="M23 4v4c.7-.3 1.3-1 1.3-2s-.6-1.7-1.3-2z" fill={p.color||'currentColor'} fillOpacity="0.5"/>
    </svg>
  ),
};
window.Icon = Icon;

// ───────── Status bar ─────────
function StatusBar({ time = '9:41', color = 'auto' }) {
  return (
    <div className="status-bar" style={ color !== 'auto' ? { color } : {} }>
      <span>{time}</span>
      <div className="right">
        <Icon.signal />
        <Icon.wifi />
        <Icon.battery />
      </div>
    </div>
  );
}
window.StatusBar = StatusBar;

// ───────── Tab bar ─────────
// Order: Home, Expenses, Reports, Assistant, Settings.
// Assistant tab uses the CapybaraGlyph (face only, no orange) so it reads at 22px.
function TabBar({ active = 'home', mode = 'light' }) {
  const tabs = [
    { id: 'home',      label: 'Home',     icon: 'house2' },
    { id: 'expenses',  label: 'Expenses', icon: 'receipt' },
    { id: 'reports',   label: 'Reports',  icon: 'chartPie' },
    { id: 'assistant', label: 'Assistant', icon: 'capy' },
    { id: 'settings',  label: 'Settings', icon: 'settings' },
  ];
  return (
    <div className="tab-bar">
      {tabs.map(t => (
        <div key={t.id} className="tab" data-active={t.id === active}>
          {t.icon === 'capy'
            ? <CapybaraGlyph size={24} active={t.id === active} mode={mode} />
            : React.createElement(Icon[t.icon], { size: 24, weight: 'medium' })}
          <span className="label">{t.label}</span>
        </div>
      ))}
    </div>
  );
}
window.TabBar = TabBar;

// ───────── FAB ─────────
function Fab({ icon = 'plus', onClick }) {
  const I = Icon[icon];
  return (
    <div className="fab" onClick={onClick}>
      <I size={26} weight="semibold" color="currentColor" />
    </div>
  );
}
window.Fab = Fab;

// ───────── Avatar ─────────
function Avatar({ initials, idx = 0, size = 36, mode = 'light' }) {
  const c = (window.AVATARS[mode] || window.AVATARS.light)[idx % 4];
  return (
    <div className="avatar"
         style={{ width: size, height: size, background: c.bg, color: c.text,
                  fontSize: size * 0.36 }}>
      {initials}
    </div>
  );
}
window.Avatar = Avatar;

// ───────── Capybara mascot ─────────
// SVG-based, 3 states (idle, thinking, responding).
// Built from layered ellipses to read as warm, rounded, friendly. Orange-with-leaf
// signature centered on head. Subtle radial gradients give dimension without
// crossing into illustrated/cartoon territory.
function Capybara({ size = 200, state = 'idle', showOrange = true }) {
  const blink = state === 'thinking';
  const breath = state !== 'responding';
  return (
    <div style={{ width: size, height: size * 1.1, position: 'relative', display: 'inline-block' }}>
      <svg viewBox="0 0 200 220" width="100%" height="100%">
        <defs>
          <radialGradient id="capyBody" cx="50%" cy="35%" r="65%">
            <stop offset="0%" stopColor="#c89868" />
            <stop offset="100%" stopColor="#a87a4e" />
          </radialGradient>
          <radialGradient id="capyHead" cx="50%" cy="40%" r="60%">
            <stop offset="0%" stopColor="#caa07a" />
            <stop offset="100%" stopColor="#b88a5e" />
          </radialGradient>
          <radialGradient id="capyOrange" cx="35%" cy="35%" r="65%">
            <stop offset="0%" stopColor="#ffaf6c" />
            <stop offset="100%" stopColor="#e88a3a" />
          </radialGradient>
          <radialGradient id="capyNose" cx="50%" cy="30%" r="70%">
            <stop offset="0%" stopColor="#8a6248" />
            <stop offset="100%" stopColor="#6a4830" />
          </radialGradient>
        </defs>

        {/* body */}
        <g className={breath ? 'capy-breath' : ''} style={{ transformOrigin: '100px 160px' }}>
          <ellipse cx="100" cy="160" rx="68" ry="48" fill="url(#capyBody)" />
          {/* belly hint */}
          <ellipse cx="100" cy="180" rx="40" ry="18" fill="#d4a878" opacity="0.45" />
          {/* feet */}
          <ellipse cx="62" cy="200" rx="14" ry="7" fill="#a07854" />
          <ellipse cx="138" cy="200" rx="14" ry="7" fill="#a07854" />
        </g>

        {/* head */}
        <g style={{ transformOrigin: '100px 90px' }}>
          <ellipse cx="100" cy="90" rx="56" ry="50" fill="url(#capyHead)" />
          {/* cheek highlight */}
          <ellipse cx="78" cy="80" rx="22" ry="16" fill="#d4a584" opacity="0.4" />

          {/* ears */}
          <g>
            <ellipse cx="58" cy="58" rx="12" ry="10" fill="#a07854" />
            <ellipse cx="142" cy="58" rx="12" ry="10" fill="#a07854" />
            <ellipse cx="58" cy="59" rx="6" ry="5" fill="#e5b8a8" />
            <ellipse cx="142" cy="59" rx="6" ry="5" fill="#e5b8a8" />
          </g>

          {/* eyes — blink animates when 'thinking' */}
          <g className={blink ? 'capy-blink' : ''}>
            {state === 'thinking' ? (
              <>
                <rect x="76" y="89" width="10" height="2.2" rx="1" fill="#2a1d14"/>
                <rect x="114" y="89" width="10" height="2.2" rx="1" fill="#2a1d14"/>
              </>
            ) : (
              <>
                <ellipse cx="81" cy="89" rx="4.5" ry="5.2" fill="#2a1d14" />
                <ellipse cx="119" cy="89" rx="4.5" ry="5.2" fill="#2a1d14" />
                <circle cx="82.5" cy="87" r="1.3" fill="#fff" />
                <circle cx="120.5" cy="87" r="1.3" fill="#fff" />
              </>
            )}
          </g>

          {/* nose / muzzle */}
          <ellipse cx="100" cy="110" rx="13" ry="8" fill="url(#capyNose)" />
          <circle cx="96" cy="108" r="1.4" fill="#2a1d14" />
          <circle cx="104" cy="108" r="1.4" fill="#2a1d14" />
          <path d="M 96 115 Q 100 118 104 115" stroke="#5a3d28" strokeWidth="1.4" strokeLinecap="round" fill="none" />

          {/* responding: small speech curve near muzzle */}
          {state === 'responding' && (
            <g className="capy-speak">
              <circle cx="158" cy="105" r="3" fill="#fdf8f0" stroke="#b88a5e" strokeWidth="1.5" />
              <circle cx="168" cy="98" r="2" fill="#fdf8f0" stroke="#b88a5e" strokeWidth="1.5" />
            </g>
          )}
        </g>

        {/* orange + leaf signature */}
        {showOrange && (
          <g style={{ transformOrigin: '100px 30px' }}>
            <ellipse cx="103" cy="38" rx="9" ry="3" fill="#000" opacity="0.08" />
            <circle cx="100" cy="30" r="15" fill="url(#capyOrange)" />
            <ellipse cx="95" cy="26" rx="6" ry="4" fill="#ffc183" opacity="0.55" />
            {/* leaf */}
            <ellipse cx="92" cy="15" rx="6" ry="3" fill="#7ca85e" transform="rotate(-25 92 15)" />
            <path d="M 98 17 L 95 13" stroke="#5a7d3e" strokeWidth="1.6" strokeLinecap="round" />
            {/* leaf shine */}
            <ellipse cx="91" cy="14" rx="3" ry="1" fill="#9bc480" opacity="0.7" transform="rotate(-25 91 14)" />
          </g>
        )}
      </svg>
      <style>{`
        .capy-breath { animation: capyBreath 3.5s ease-in-out infinite; }
        @keyframes capyBreath { 0%,100% { transform: scaleY(1); } 50% { transform: scaleY(1.03); } }
        .capy-blink { animation: capyBlink 1.4s ease-in-out infinite; }
        @keyframes capyBlink { 0%,100% { transform: scaleY(1); } 50% { transform: scaleY(0.2); transform-origin: center 90px; } }
        .capy-speak { animation: capySpeak 1.6s ease-in-out infinite; }
        @keyframes capySpeak {
          0%,100% { opacity: 0.3; transform: translate(0, 0); }
          50% { opacity: 1; transform: translate(2px, -2px); }
        }
      `}</style>
    </div>
  );
}
window.Capybara = Capybara;

// Capybara face-only glyph for tab bar (no orange, no body, reads at 22-26px)
function CapybaraGlyph({ size = 24, active = false, mode = 'light' }) {
  const fill = active
    ? (mode === 'dark' ? '#d4a878' : '#b88a5e')
    : (mode === 'dark' ? '#6e5e4e' : '#c4b0a0');
  const ear = active
    ? (mode === 'dark' ? '#a07854' : '#8a6a4a')
    : (mode === 'dark' ? '#54483a' : '#a89684');
  return (
    <svg width={size} height={size} viewBox="0 0 24 24">
      <ellipse cx="6" cy="6.5" rx="2.4" ry="2" fill={ear} />
      <ellipse cx="18" cy="6.5" rx="2.4" ry="2" fill={ear} />
      <ellipse cx="12" cy="13" rx="9" ry="8" fill={fill} />
      <ellipse cx="9.5" cy="12" rx="1.1" ry="1.4" fill="#2a1d14" />
      <ellipse cx="14.5" cy="12" rx="1.1" ry="1.4" fill="#2a1d14" />
      <ellipse cx="12" cy="16" rx="2.2" ry="1.4" fill="#7a5840" />
    </svg>
  );
}
window.CapybaraGlyph = CapybaraGlyph;

// Inline tiny capybara (chat message avatar — 22px circle, full character minus body)
function CapybaraAvatar({ size = 28, mode = 'light' }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: mode === 'dark' ? '#322a22' : '#f0e0c8',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      overflow: 'hidden', flexShrink: 0,
    }}>
      <svg width={size * 0.95} height={size * 0.95} viewBox="0 0 24 24">
        <ellipse cx="6" cy="9" rx="2" ry="1.7" fill="#a07854" />
        <ellipse cx="18" cy="9" rx="2" ry="1.7" fill="#a07854" />
        <ellipse cx="12" cy="13" rx="7.5" ry="6.5" fill="#b88a5e" />
        <ellipse cx="9.5" cy="12" rx="1" ry="1.2" fill="#2a1d14" />
        <ellipse cx="14.5" cy="12" rx="1" ry="1.2" fill="#2a1d14" />
        <ellipse cx="12" cy="15.5" rx="2" ry="1.2" fill="#7a5840" />
        <circle cx="12" cy="6" r="2.2" fill="#f29545" />
        <ellipse cx="10.5" cy="4" rx="1.3" ry="0.6" fill="#7ca85e" transform="rotate(-25 10.5 4)" />
      </svg>
    </div>
  );
}
window.CapybaraAvatar = CapybaraAvatar;
