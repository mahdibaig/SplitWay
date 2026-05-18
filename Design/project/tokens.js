// Splitway design tokens — Light + Dark
window.LIGHT = {
  // surfaces
  bg: '#f5ede0', surface: '#fdf8f0', surface2: '#f0e8d8', surface3: '#e8dcc8',
  // text
  text1: '#2a1d14', text2: '#8a7a6a', text3: '#c4b0a0',
  // brand
  brand: '#b88a5e', brand2: '#8a6a4a', brandSoft: '#f0e0c8',
  // semantic
  warn: '#d4824a', warnSoft: '#f5d8c2', success: '#5a7d3e', successSoft: '#dfe9d0',
  // cta
  cta: '#2a1d14', ctaText: '#fdf8f0',
  // border / divider
  border: 'rgba(42,29,20,0.08)', divider: 'rgba(42,29,20,0.06)',
  // shadows
  shadowSm: '0 1px 2px rgba(42,29,20,0.04)',
  shadowMd: '0 4px 12px rgba(42,29,20,0.06), 0 1px 2px rgba(42,29,20,0.04)',
  shadowLg: '0 12px 32px rgba(42,29,20,0.10), 0 2px 6px rgba(42,29,20,0.05)',
};

window.DARK = {
  // surfaces — warm dark browns, never cool gray
  bg: '#1a130d', surface: '#26201a', surface2: '#322a22', surface3: '#3d342a',
  // text
  text1: '#f5ede0', text2: '#a89888', text3: '#6e5e4e',
  // brand — lifted so it reads on dark warm
  brand: '#d4a878', brand2: '#b88a5e', brandSoft: '#3d2f22',
  // semantic
  warn: '#e89968', warnSoft: '#3d2a20', success: '#8aab68', successSoft: '#2a3320',
  // cta — on dark, use brand-light as primary (dark CTA disappears)
  cta: '#f5ede0', ctaText: '#1a130d',
  // border
  border: 'rgba(245,237,224,0.08)', divider: 'rgba(245,237,224,0.06)',
  // shadows
  shadowSm: '0 1px 2px rgba(0,0,0,0.4)',
  shadowMd: '0 4px 16px rgba(0,0,0,0.5)',
  shadowLg: '0 16px 40px rgba(0,0,0,0.6)',
};

// Per-person avatar colors (same across modes; dark mode darkens the bg & lightens the text)
window.AVATARS = {
  light: [
    { bg: '#c0d4b8', text: '#3b6d11' }, // sage
    { bg: '#e5b8a8', text: '#993556' }, // pink
    { bg: '#d0c4d8', text: '#534ab7' }, // purple
    { bg: '#e4c8c0', text: '#993c1d' }, // coral
  ],
  dark: [
    { bg: '#3b5a2b', text: '#d5ecc4' },
    { bg: '#6a3344', text: '#f5d4d8' },
    { bg: '#3f3a6e', text: '#e0d8f0' },
    { bg: '#6a3a26', text: '#f5d8c8' },
  ],
};

// Category colors — semantic, used consistently
window.CATEGORIES = [
  { id: 'groceries',  name: 'Groceries',  icon: 'cart',        light: { bg: '#f0e0c8', fg: '#b88a5e' }, dark: { bg: '#3d2f22', fg: '#d4a878' } },
  { id: 'dining',     name: 'Dining out', icon: 'fork',        light: { bg: '#e8d4c0', fg: '#d4824a' }, dark: { bg: '#3a2a1f', fg: '#e89968' } },
  { id: 'housing',    name: 'Housing',    icon: 'house',       light: { bg: '#e8dcc8', fg: '#8a6a4a' }, dark: { bg: '#332a1f', fg: '#c4a078' } },
  { id: 'utilities',  name: 'Utilities',  icon: 'bolt',        light: { bg: '#e0e8d0', fg: '#5a7d3e' }, dark: { bg: '#2a3322', fg: '#8aab68' } },
  { id: 'transport',  name: 'Transport',  icon: 'car',         light: { bg: '#d0d8e0', fg: '#4a6580' }, dark: { bg: '#222a33', fg: '#7a95b0' } },
  { id: 'subscriptions', name: 'Subscriptions', icon: 'play',  light: { bg: '#d0c4d8', fg: '#534ab7' }, dark: { bg: '#2a253a', fg: '#a89dd8' } },
  { id: 'health',     name: 'Health',     icon: 'heart',       light: { bg: '#e5b8a8', fg: '#993556' }, dark: { bg: '#3a2228', fg: '#d8909a' } },
  { id: 'shopping',   name: 'Shopping',   icon: 'bag',         light: { bg: '#e4c8c0', fg: '#993c1d' }, dark: { bg: '#3a2218', fg: '#d89878' } },
  { id: 'fun',        name: 'Fun',        icon: 'sparkle',     light: { bg: '#e0d4b0', fg: '#7d6a1e' }, dark: { bg: '#332e1c', fg: '#c4b07a' } },
  { id: 'other',      name: 'Other',      icon: 'dots',        light: { bg: '#e0d4c8', fg: '#7a6555' }, dark: { bg: '#2e271f', fg: '#a8988a' } },
];

// Typography stack
window.FONTS = {
  ui: '-apple-system, "SF Pro Text", "SF Pro Display", system-ui, sans-serif',
  serif: '"Newsreader", "Source Serif Pro", Georgia, "Times New Roman", serif',
  mono: '"SF Mono", "JetBrains Mono", Menlo, monospace',
};
