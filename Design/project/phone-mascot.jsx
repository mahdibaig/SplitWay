/* Phone wrapper + Capybara mascot states gallery + App icon + Empty states */

const { Icon, StatusBar, TabBar, Fab, Avatar, Capybara, CapybaraGlyph } = window;

// Phone wrapper — sets CSS variables based on mode, applies bezel.
function Phone({ mode = 'light', children, screenLabel }) {
  const T = mode === 'dark' ? window.DARK : window.LIGHT;
  const vars = {
    '--bg': T.bg, '--surface': T.surface, '--surface2': T.surface2, '--surface3': T.surface3,
    '--text1': T.text1, '--text2': T.text2, '--text3': T.text3,
    '--brand': T.brand, '--brand2': T.brand2, '--brandSoft': T.brandSoft,
    '--warn': T.warn, '--warnSoft': T.warnSoft, '--success': T.success, '--successSoft': T.successSoft,
    '--cta': T.cta, '--cta-text': T.ctaText,
    '--border': T.border, '--divider': T.divider,
    '--shadow-sm': T.shadowSm, '--shadow-md': T.shadowMd, '--shadow-lg': T.shadowLg,
  };
  return (
    <div className="phone bezel" data-mode={mode} data-screen-label={screenLabel} style={vars}>
      <div className="screen" style={vars}>
        <div className="island" />
        <div className="content">{children}</div>
        <div className="home-ind" />
      </div>
    </div>
  );
}
window.Phone = Phone;

// Capybara States Gallery — for design system reference
function CapybaraStates({ mode = 'light' }) {
  const bg = mode === 'dark' ? window.DARK.bg : window.LIGHT.bg;
  const surface = mode === 'dark' ? window.DARK.surface : window.LIGHT.surface;
  const text1 = mode === 'dark' ? window.DARK.text1 : window.LIGHT.text1;
  const text2 = mode === 'dark' ? window.DARK.text2 : window.LIGHT.text2;
  return (
    <div style={{
      width: 760, padding: 32, background: bg, color: text1,
      borderRadius: 24, fontFamily: '-apple-system, system-ui',
    }}>
      <p style={{ margin: 0, fontSize: 13, color: text2, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>Mascot</p>
      <h2 style={{ margin: '4px 0 4px', fontSize: 28, letterSpacing: -0.6, fontWeight: 600 }}>The Splitway capybara</h2>
      <p style={{ margin: 0, fontSize: 14, color: text2, maxWidth: 540, lineHeight: 1.5 }}>
        Three states — idle, thinking, responding. Used only in the Assistant tab and onboarding welcome.
        Never decorative.
      </p>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16, marginTop: 28 }}>
        {[
          { state: 'idle',       title: 'Idle',       desc: 'Default state. Subtle breathing animation. Bright eyes.' },
          { state: 'thinking',   title: 'Thinking',   desc: 'During query. Eyes close to "—". Subtle pulse on body.' },
          { state: 'responding', title: 'Responding', desc: 'While text streams. Small speech swirls beside muzzle.' },
        ].map(s => (
          <div key={s.state} style={{
            background: surface, borderRadius: 18, padding: 22,
            display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 10,
          }}>
            <div style={{ height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Capybara size={180} state={s.state} />
            </div>
            <p style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: -0.2 }}>{s.title}</p>
            <p style={{ margin: 0, fontSize: 12, color: text2, lineHeight: 1.45 }}>{s.desc}</p>
            <code style={{ fontSize: 11, padding: '3px 8px', background: bg, borderRadius: 6, color: text2 }}>
              .capybara[state="{s.state}"]
            </code>
          </div>
        ))}
      </div>

      {/* Scale uses */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 16, marginTop: 24 }}>
        {[
          { size: 180, label: 'Hero · Assistant empty', sub: '180px' },
          { size: 72,  label: 'Chat header avatar',     sub: '40px' },
          { size: 28,  label: 'Per-message avatar',     sub: '28px (no orange)' },
          { size: 24,  label: 'Tab bar glyph',          sub: '24px (face only)' },
        ].map((s, i) => (
          <div key={i} style={{
            background: surface, borderRadius: 18, padding: 18,
            display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', gap: 8,
            minHeight: 200, justifyContent: 'center',
          }}>
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {i < 3
                ? <Capybara size={s.size} state="idle" showOrange={i < 2} />
                : <CapybaraGlyph size={s.size} active mode={mode} />}
            </div>
            <p style={{ margin: 0, fontSize: 12, color: text2 }}>{s.label}</p>
            <code style={{ fontSize: 10, color: text2 }}>{s.sub}</code>
          </div>
        ))}
      </div>
    </div>
  );
}
window.CapybaraStates = CapybaraStates;

// App icon ----------------------------------------------------------------
// Original mark: rounded square cream→tan gradient with capybara silhouette
// peeking up, the signature orange-with-leaf positioned center, anchored over
// the mascot's head so the orange reads at any size (even down to 60px).
function AppIcon({ size = 200, radius = 0.225 }) {
  const r = size * radius;
  return (
    <div style={{
      width: size, height: size, borderRadius: r,
      overflow: 'hidden', position: 'relative',
      boxShadow: `0 ${size*0.04}px ${size*0.12}px rgba(42,29,20,0.22), 0 ${size*0.01}px ${size*0.03}px rgba(42,29,20,0.12)`,
    }}>
      <svg viewBox="0 0 200 200" width={size} height={size}>
        <defs>
          <linearGradient id="iconBg" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor="#fbeed4" />
            <stop offset="55%" stopColor="#f5dca8" />
            <stop offset="100%" stopColor="#e8b878" />
          </linearGradient>
          <radialGradient id="iconCapy" cx="50%" cy="40%" r="60%">
            <stop offset="0%" stopColor="#c69a72" />
            <stop offset="100%" stopColor="#9d6f47" />
          </radialGradient>
          <radialGradient id="iconOrange" cx="35%" cy="35%" r="65%">
            <stop offset="0%" stopColor="#ffbb7a" />
            <stop offset="100%" stopColor="#e8843a" />
          </radialGradient>
        </defs>
        <rect width="200" height="200" fill="url(#iconBg)" />
        {/* subtle warm glow */}
        <circle cx="100" cy="120" r="100" fill="#fff" opacity="0.12" />

        {/* capybara head peeking up from the bottom */}
        <ellipse cx="100" cy="180" rx="90" ry="60" fill="url(#iconCapy)" />
        {/* ears */}
        <ellipse cx="58" cy="112" rx="14" ry="11" fill="#9d6f47" />
        <ellipse cx="142" cy="112" rx="14" ry="11" fill="#9d6f47" />
        <ellipse cx="58" cy="114" rx="7" ry="5" fill="#e5b8a8" />
        <ellipse cx="142" cy="114" rx="7" ry="5" fill="#e5b8a8" />
        {/* eyes */}
        <ellipse cx="74" cy="146" rx="6" ry="7" fill="#2a1d14" />
        <ellipse cx="126" cy="146" rx="6" ry="7" fill="#2a1d14" />
        <circle cx="76" cy="143" r="1.8" fill="#fff" />
        <circle cx="128" cy="143" r="1.8" fill="#fff" />
        {/* nose */}
        <ellipse cx="100" cy="172" rx="18" ry="11" fill="#6a4830" />
        <circle cx="94" cy="170" r="1.8" fill="#2a1d14" />
        <circle cx="106" cy="170" r="1.8" fill="#2a1d14" />

        {/* signature orange + leaf — anchored on top of head, big enough to read at any scale */}
        <ellipse cx="103" cy="96" rx="22" ry="6" fill="#000" opacity="0.10" />
        <circle cx="100" cy="84" r="28" fill="url(#iconOrange)" />
        <ellipse cx="89" cy="76" rx="14" ry="8" fill="#ffc89a" opacity="0.55" />
        {/* leaf */}
        <ellipse cx="85" cy="55" rx="13" ry="6" fill="#7ca85e" transform="rotate(-30 85 55)" />
        <ellipse cx="83" cy="53" rx="7" ry="2" fill="#9bc480" opacity="0.7" transform="rotate(-30 83 53)" />
        <path d="M 98 60 L 90 51" stroke="#5a7d3e" strokeWidth="3" strokeLinecap="round" />
      </svg>
    </div>
  );
}
window.AppIcon = AppIcon;

function AppIconSheet({ mode = 'light' }) {
  const bg = mode === 'dark' ? window.DARK.bg : window.LIGHT.bg;
  const surface = mode === 'dark' ? window.DARK.surface : window.LIGHT.surface;
  const text1 = mode === 'dark' ? window.DARK.text1 : window.LIGHT.text1;
  const text2 = mode === 'dark' ? window.DARK.text2 : window.LIGHT.text2;
  return (
    <div style={{ width: 760, padding: 32, background: bg, color: text1, borderRadius: 24, fontFamily: '-apple-system, system-ui' }}>
      <p style={{ margin: 0, fontSize: 13, color: text2, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>App icon</p>
      <h2 style={{ margin: '4px 0 4px', fontSize: 28, letterSpacing: -0.6, fontWeight: 600 }}>Splitway</h2>
      <p style={{ margin: 0, fontSize: 14, color: text2, maxWidth: 540, lineHeight: 1.5 }}>
        Capybara peeking from the bottom edge — the signature orange-with-leaf sits where the
        eye lands, readable from 60px to 1024px. Warm cream-to-tan gradient. Not fintech.
      </p>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, marginTop: 28, alignItems: 'center' }}>
        <div style={{ background: surface, borderRadius: 18, padding: 24, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <AppIcon size={240} />
        </div>
        <div style={{ background: surface, borderRadius: 18, padding: 24, display: 'flex', flexDirection: 'column', gap: 16 }}>
          {[1024, 180, 120, 80, 60, 40].map(s => (
            <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <AppIcon size={s > 96 ? 96 : s} />
              <div>
                <p style={{ margin: 0, fontSize: 14, fontWeight: 600 }}>{s}×{s}</p>
                <p style={{ margin: '2px 0 0', fontSize: 12, color: text2 }}>{
                  s === 1024 ? 'App Store' : s === 180 ? 'Home screen @3x' :
                  s === 120 ? 'Spotlight @3x' : s === 80 ? 'Settings @2x' :
                  s === 60 ? 'Notification @3x' : 'Settings @1x'
                }</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
window.AppIconSheet = AppIconSheet;

// Illustrated empty states (no capybara — generic warm-rounded world) -----
// Each is a small composition using only the brand palette + soft geometry.

function EmptyNoExpenses({ size = 160 }) {
  return (
    <svg width={size} height={size * 0.9} viewBox="0 0 200 180">
      <defs>
        <linearGradient id="emp1" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#fdf8f0" /><stop offset="100%" stopColor="#f0e0c8" />
        </linearGradient>
      </defs>
      {/* receipt paper */}
      <path d="M 60 30 L 140 30 L 140 145 L 130 138 L 120 145 L 110 138 L 100 145 L 90 138 L 80 145 L 70 138 L 60 145 Z"
            fill="url(#emp1)" stroke="#b88a5e" strokeWidth="2" />
      <line x1="74" y1="60" x2="120" y2="60" stroke="#c4b0a0" strokeWidth="2.5" strokeLinecap="round" />
      <line x1="74" y1="76" x2="110" y2="76" stroke="#c4b0a0" strokeWidth="2.5" strokeLinecap="round" />
      <line x1="74" y1="92" x2="115" y2="92" stroke="#c4b0a0" strokeWidth="2.5" strokeLinecap="round" />
      {/* leaf */}
      <ellipse cx="55" cy="50" rx="14" ry="6" fill="#7ca85e" transform="rotate(-30 55 50)" />
      <path d="M 65 55 L 50 45" stroke="#5a7d3e" strokeWidth="2" strokeLinecap="round" />
      {/* sparkle */}
      <circle cx="155" cy="55" r="4" fill="#f29545" />
      <circle cx="160" cy="58" r="2" fill="#f29545" opacity="0.5" />
    </svg>
  );
}

function EmptyAllSettled({ size = 160 }) {
  return (
    <svg width={size} height={size * 0.9} viewBox="0 0 200 180">
      {/* sun behind */}
      <circle cx="100" cy="105" r="64" fill="#f5dca8" opacity="0.7" />
      <circle cx="100" cy="105" r="48" fill="#e8b878" opacity="0.8" />
      {/* two hands meeting / coins balanced */}
      <circle cx="65" cy="105" r="22" fill="#b88a5e" stroke="#8a6a4a" strokeWidth="2.5" />
      <text x="65" y="111" textAnchor="middle" fill="#fdf8f0" fontSize="20" fontWeight="600" fontFamily="serif">$</text>
      <circle cx="135" cy="105" r="22" fill="#5a7d3e" stroke="#3e5926" strokeWidth="2.5" />
      <text x="135" y="111" textAnchor="middle" fill="#fdf8f0" fontSize="20" fontWeight="600">✓</text>
      {/* spark lines */}
      <path d="M 100 50 L 100 60 M 70 60 L 78 68 M 130 60 L 122 68" stroke="#d4824a" strokeWidth="2.5" strokeLinecap="round" />
    </svg>
  );
}

function EmptyNoBudgets({ size = 160 }) {
  return (
    <svg width={size} height={size * 0.9} viewBox="0 0 200 180">
      {/* donut chart slices, broken */}
      <circle cx="100" cy="95" r="50" fill="none" stroke="#f0e0c8" strokeWidth="18" />
      <path d="M 100 45 A 50 50 0 0 1 143 120" stroke="#b88a5e" strokeWidth="18" fill="none" strokeLinecap="round" />
      <path d="M 100 45 A 50 50 0 0 0 57 120" stroke="#d4824a" strokeWidth="18" fill="none" strokeLinecap="round" opacity="0.5" strokeDasharray="3 6" />
      <circle cx="100" cy="95" r="22" fill="#fdf8f0" />
      <circle cx="100" cy="95" r="4" fill="#b88a5e" />
    </svg>
  );
}

function EmptyNoReceipts({ size = 160 }) {
  return (
    <svg width={size} height={size * 0.9} viewBox="0 0 200 180">
      {/* camera frame */}
      <rect x="40" y="48" width="120" height="90" rx="14" fill="#fdf8f0" stroke="#b88a5e" strokeWidth="2.5" />
      <circle cx="100" cy="93" r="22" fill="none" stroke="#b88a5e" strokeWidth="2.5" />
      <circle cx="100" cy="93" r="10" fill="#b88a5e" opacity="0.3" />
      <rect x="80" y="38" width="40" height="14" rx="4" fill="#b88a5e" />
      {/* orange + leaf */}
      <circle cx="150" cy="60" r="10" fill="#f29545" />
      <ellipse cx="146" cy="52" rx="6" ry="2.5" fill="#7ca85e" transform="rotate(-30 146 52)" />
    </svg>
  );
}

function EmptyStatesSheet({ mode = 'light' }) {
  const bg = mode === 'dark' ? window.DARK.bg : window.LIGHT.bg;
  const surface = mode === 'dark' ? window.DARK.surface : window.LIGHT.surface;
  const text1 = mode === 'dark' ? window.DARK.text1 : window.LIGHT.text1;
  const text2 = mode === 'dark' ? window.DARK.text2 : window.LIGHT.text2;
  const items = [
    { Comp: EmptyNoExpenses, title: 'No expenses yet', body: 'Add your first to start splitting.', cta: 'Add expense' },
    { Comp: EmptyAllSettled, title: 'All settled up', body: "Everyone's even. Quiet week.", cta: null },
    { Comp: EmptyNoBudgets, title: 'No budgets set', body: 'Set monthly limits to track spending.', cta: 'Set a budget' },
    { Comp: EmptyNoReceipts, title: 'No receipts yet', body: 'Scan one to auto-split line items.', cta: 'Scan receipt' },
  ];
  return (
    <div style={{ width: 760, padding: 32, background: bg, color: text1, borderRadius: 24, fontFamily: '-apple-system, system-ui' }}>
      <p style={{ margin: 0, fontSize: 13, color: text2, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>Empty states</p>
      <h2 style={{ margin: '4px 0 4px', fontSize: 28, letterSpacing: -0.6, fontWeight: 600 }}>Warm, never empty</h2>
      <p style={{ margin: 0, fontSize: 14, color: text2, maxWidth: 540, lineHeight: 1.5 }}>
        Capybara-world illustrations — same palette and rounded language as the mascot, without using the mascot itself.
      </p>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 28 }}>
        {items.map(({ Comp, title, body, cta }, i) => (
          <div key={i} style={{ background: surface, borderRadius: 20, padding: 28, textAlign: 'center' }}>
            <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
              <Comp size={140} />
            </div>
            <p className="serif-i" style={{ margin: '4px 0', fontSize: 20, color: text1 }}>{title}</p>
            <p style={{ margin: '0 0 16px', fontSize: 13, color: text2 }}>{body}</p>
            {cta && <button style={{
              background: 'transparent', border: '1.5px solid ' + text1, color: text1,
              padding: '8px 18px', borderRadius: 100, fontWeight: 600, fontSize: 13, cursor: 'pointer',
            }}>{cta}</button>}
          </div>
        ))}
      </div>
    </div>
  );
}
window.EmptyStatesSheet = EmptyStatesSheet;
window.EmptyNoExpenses = EmptyNoExpenses;
window.EmptyAllSettled = EmptyAllSettled;
window.EmptyNoBudgets = EmptyNoBudgets;
window.EmptyNoReceipts = EmptyNoReceipts;
