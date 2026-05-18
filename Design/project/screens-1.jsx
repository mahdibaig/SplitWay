/* Splitway screens — Part 1: Onboarding (4 screens) + Settings + Budgets */

const { Icon, StatusBar, TabBar, Fab, Avatar, Capybara, CapybaraAvatar } = window;

// Onboarding: Welcome ----------------------------------------------------
function ScreenWelcome({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="01 Welcome">
      <StatusBar />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: '12px 32px 40px' }}>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', textAlign: 'center', gap: 22 }}>
          <Capybara size={220} state="idle" />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <p className="serif-i" style={{ margin: 0, fontSize: 22, color: 'var(--text2)' }}>Welcome to</p>
            <h1 className="serif" style={{ margin: 0, fontSize: 56, lineHeight: 1, letterSpacing: -1.5, fontWeight: 600 }}>Splitway</h1>
          </div>
          <p style={{ margin: '8px 0 0', fontSize: 16, lineHeight: 1.45, color: 'var(--text2)', maxWidth: 280 }}>
            Track and split expenses with the people you live with — peacefully.
          </p>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14, alignItems: 'center' }}>
          <button className="btn-primary">Get started</button>
          <p style={{ margin: 0, fontSize: 12, color: 'var(--text3)' }}>
            By continuing, you agree to our <u>Privacy Policy</u>
          </p>
        </div>
      </div>
    </Phone>
  );
}

function StepHeader({ step, of, title, subtitle }) {
  return (
    <div style={{ padding: '8px 24px 28px' }}>
      <div style={{ display: 'flex', gap: 6, marginBottom: 24 }}>
        {Array.from({ length: of }).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 100,
            background: i < step ? 'var(--brand)' : 'var(--surface2)',
          }} />
        ))}
      </div>
      <p className="eyebrow" style={{ margin: '0 0 10px' }}>Step {step} of {of}</p>
      <h1 className="serif" style={{ margin: '0 0 8px', fontSize: 30, lineHeight: 1.1, fontWeight: 600, letterSpacing: -0.6 }}>{title}</h1>
      <p style={{ margin: 0, fontSize: 15, color: 'var(--text2)', lineHeight: 1.5 }}>{subtitle}</p>
    </div>
  );
}

// Onboarding: Name household --------------------------------------------
function ScreenName({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="02 Name household">
      <StatusBar />
      <div className="scroll" style={{ paddingTop: 12 }}>
        <StepHeader step={1} of={3} title="Name your household" subtitle="This is what you'll see when you open the app. You can change it later." />
        <div style={{ padding: '0 24px' }}>
          <div className="card" style={{ padding: '18px 18px', border: '1.5px solid var(--brand)', borderRadius: 16 }}>
            <p className="eyebrow" style={{ margin: '0 0 4px' }}>Household name</p>
            <input className="text-input" defaultValue="The Mahmoud House" />
          </div>
          <p style={{ margin: '24px 0 12px', fontSize: 13, color: 'var(--text2)', fontWeight: 500 }}>Or pick a quick name</p>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {['Our House', 'Home', 'The Smiths', 'Family'].map(n => <span key={n} className="chip">{n}</span>)}
          </div>
        </div>
      </div>
      <div style={{ padding: '12px 24px 36px' }}>
        <button className="btn-primary">Continue</button>
      </div>
    </Phone>
  );
}

// Onboarding: Groups -----------------------------------------------------
function ScreenGroups({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="03 Groups setup">
      <StatusBar />
      <div className="scroll" style={{ paddingTop: 12 }}>
        <StepHeader step={2} of={3} title="Set up groups" subtitle="Do people in your household form groups, like couples or families?" />
        <div style={{ padding: '0 24px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div className="card" style={{ padding: 18, border: '1.5px solid var(--brand)', borderRadius: 18, position: 'relative' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
              <div className="icon-tile md" style={{ background: 'var(--brandSoft)', color: 'var(--brand2)' }}>
                <Icon.users size={22} weight="medium" />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: 16, fontWeight: 600, letterSpacing: -0.2 }}>Yes, set up groups</p>
                <p style={{ margin: '4px 0 0', fontSize: 13, color: 'var(--text2)', lineHeight: 1.45 }}>
                  Bills can be split between groups (50/50, percentage, etc.) Tap to expand to individuals.
                </p>
              </div>
              <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'var(--brand)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon.check size={14} color="var(--cta-text)" weight="semibold" />
              </div>
            </div>
          </div>
          <div className="card" style={{ padding: 18, border: '1.5px solid var(--border)', borderRadius: 18 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
              <div className="icon-tile md" style={{ background: 'var(--surface2)', color: 'var(--text2)' }}>
                <Icon.user size={22} weight="medium" />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: 16, fontWeight: 600, letterSpacing: -0.2 }}>No, just individuals</p>
                <p style={{ margin: '4px 0 0', fontSize: 13, color: 'var(--text2)', lineHeight: 1.45 }}>
                  Everyone splits expenses on their own. Great for roommates.
                </p>
              </div>
              <div style={{ width: 22, height: 22, borderRadius: '50%', border: '2px solid var(--text3)' }} />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start', padding: '14px 16px', background: 'var(--successSoft)', borderRadius: 14, marginTop: 4 }}>
            <Icon.info size={18} color="var(--success)" weight="medium" style={{ flexShrink: 0, marginTop: 1 }} />
            <p style={{ margin: 0, fontSize: 13, color: 'var(--success)', lineHeight: 1.4, fontWeight: 500 }}>
              You can change this anytime in Settings.
            </p>
          </div>
        </div>
      </div>
      <div style={{ padding: '12px 24px 36px' }}>
        <button className="btn-primary">Continue</button>
      </div>
    </Phone>
  );
}

// Onboarding: AI Consent -------------------------------------------------
function ScreenAIConsent({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="04 AI consent">
      <StatusBar />
      <div className="scroll" style={{ paddingTop: 12 }}>
        <StepHeader step={3} of={3} title="Enable the assistant?" subtitle="Ask questions about your spending in plain English." />
        <div style={{ padding: '0 24px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div className="card" style={{ padding: 18, borderRadius: 18 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
              <div className="icon-tile md" style={{ background: 'var(--successSoft)', color: 'var(--success)' }}>
                <Icon.shield size={22} weight="medium" />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: -0.2 }}>Your data stays private</p>
                <p style={{ margin: '4px 0 0', fontSize: 13, color: 'var(--text2)', lineHeight: 1.45 }}>
                  Only your question and the relevant expenses are sent to Anthropic. Nothing is stored or used to train models.
                </p>
              </div>
            </div>
          </div>
          <div className="card" style={{ padding: 18, borderRadius: 18 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14 }}>
              <div className="icon-tile md" style={{ background: 'var(--brandSoft)', color: 'var(--brand2)' }}>
                <Icon.toggle size={22} weight="medium" />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: -0.2 }}>Turn off anytime</p>
                <p style={{ margin: '4px 0 0', fontSize: 13, color: 'var(--text2)', lineHeight: 1.45 }}>
                  Disable it in Settings — the assistant tab will hide and no data leaves your devices.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ padding: '12px 24px 36px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <button className="btn-primary">Enable assistant</button>
        <button style={{ background: 'transparent', border: 0, padding: '14px', color: 'var(--text2)', fontWeight: 500, fontSize: 15, cursor: 'pointer' }}>Skip for now</button>
      </div>
    </Phone>
  );
}

// Settings ---------------------------------------------------------------
function SettingsRow({ icon, color, label, detail, isLast, danger }) {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px', minHeight: 52 }}>
        {icon && <div className="icon-tile sm" style={{ background: color.bg, color: color.fg }}>
          {React.createElement(Icon[icon], { size: 17, weight: 'medium' })}
        </div>}
        <div style={{ flex: 1, fontSize: 15, fontWeight: 500, letterSpacing: -0.2, color: danger ? 'var(--warn)' : 'var(--text1)' }}>{label}</div>
        {detail && <span style={{ fontSize: 14, color: 'var(--text2)' }}>{detail}</span>}
        <Icon.chevronR size={14} color="var(--text3)" weight="medium" />
      </div>
      {!isLast && <div className="row-sep" />}
    </>
  );
}

function ScreenSettings({ mode = 'light' }) {
  const sec = (cat) => ({ bg: cat.bg, fg: cat.fg });
  return (
    <Phone mode={mode} screenLabel="05 Settings">
      <StatusBar />
      <div className="scroll" style={{ padding: '4px 0 120px' }}>
        <div style={{ padding: '6px 22px 16px' }}>
          <h1 className="h-large" style={{ margin: 0 }}>Settings</h1>
        </div>

        {/* Profile hero */}
        <div style={{ padding: '0 18px 22px' }}>
          <div className="card" style={{ padding: 18, display: 'flex', alignItems: 'center', gap: 14, borderRadius: 20 }}>
            <Avatar initials="H" idx={0} size={56} mode={mode} />
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 17, fontWeight: 600, letterSpacing: -0.3 }}>Hamza Mahmoud</p>
              <p style={{ margin: '2px 0 0', fontSize: 13, color: 'var(--text2)' }}>Mahmoud family · Member since Nov 10</p>
            </div>
            <Icon.edit size={18} color="var(--brand)" weight="medium" />
          </div>
        </div>

        <SettingsGroup label="Household" mode={mode}>
          <SettingsRow icon="house2" color={{ bg: 'var(--brandSoft)', fg: 'var(--brand2)' }} label="The Mahmoud House" detail="" />
          <SettingsRow icon="users" color={{ bg: '#e0e8d0', fg: '#5a7d3e' }} label="Members & groups" detail="4 · 2 groups" />
          <SettingsRow icon="link" color={{ bg: '#d0d8e0', fg: '#4a6580' }} label="Invite a member" />
          <SettingsRow icon="calendar" color={{ bg: '#e8d4c0', fg: '#d4824a' }} label="Recurring expenses" detail="5 active" isLast />
        </SettingsGroup>

        <SettingsGroup label="Money" mode={mode}>
          <SettingsRow icon="chartPie" color={{ bg: '#e0d4b0', fg: '#7d6a1e' }} label="Budgets" detail="6 set" />
          <SettingsRow icon="wallet" color={{ bg: '#dfe9d0', fg: '#5a7d3e' }} label="Settlement history" detail="12" isLast />
        </SettingsGroup>

        <SettingsGroup label="Preferences" mode={mode}>
          <SettingsRow icon="bell" color={{ bg: '#e5b8a8', fg: '#993556' }} label="Notifications" detail="On" />
          <SettingsRow icon="sparkle" color={{ bg: 'var(--brandSoft)', fg: 'var(--brand2)' }} label="AI assistant" detail="On" />
          <SettingsRow icon="camera" color={{ bg: '#d0c4d8', fg: '#534ab7' }} label="Receipt storage" detail="12 months" />
          <SettingsRow icon="sparkle" color={{ bg: '#e8dcc8', fg: '#8a6a4a' }} label="Appearance" detail={mode === 'dark' ? 'Dark' : 'Auto'} isLast />
        </SettingsGroup>

        <SettingsGroup label="About" mode={mode}>
          <SettingsRow icon="shield" color={{ bg: '#dfe9d0', fg: '#5a7d3e' }} label="Privacy policy" />
          <SettingsRow icon="info" color={{ bg: '#e8dcc8', fg: '#8a6a4a' }} label="Version" detail="1.0 (b3)" isLast />
        </SettingsGroup>
      </div>
      <TabBar active="settings" mode={mode} />
    </Phone>
  );
}

function SettingsGroup({ label, children, mode }) {
  return (
    <>
      <p className="eyebrow" style={{ margin: '20px 28px 8px' }}>{label}</p>
      <div style={{ padding: '0 18px' }}>
        <div className="card" style={{ borderRadius: 16, overflow: 'hidden' }}>{children}</div>
      </div>
    </>
  );
}

// Budgets ----------------------------------------------------------------
function BudgetRow({ category, spent, budget, mode = 'light' }) {
  const pct = Math.min(100, Math.round((spent / budget) * 100));
  const over = spent > budget;
  const onTrack = pct < 80;
  const color = over ? 'var(--warn)' : onTrack ? 'var(--success)' : 'var(--brand)';
  return (
    <div className="card" style={{
      padding: 16, marginBottom: 10, borderRadius: 16,
      borderLeft: over ? '4px solid var(--warn)' : 'none',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <div className="icon-tile sm" style={{ background: category[mode].bg, color: category[mode].fg }}>
          {React.createElement(Icon[category.icon], { size: 18, weight: 'medium' })}
        </div>
        <div style={{ flex: 1 }}>
          <p style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: -0.2 }}>{category.name}</p>
        </div>
        <p className="num" style={{ margin: 0, fontSize: 16, fontWeight: 600, color: over ? 'var(--warn)' : 'var(--text1)' }}>
          ${spent} <span style={{ color: 'var(--text3)', fontWeight: 500 }}>/ ${budget}</span>
        </p>
      </div>
      <div className="bar"><div style={{ width: `${pct}%`, background: color }} /></div>
      <p style={{ margin: '8px 0 0', fontSize: 12, color: over ? 'var(--warn)' : 'var(--text2)', fontWeight: 500 }}>
        {over ? `$${spent - budget} over` : `$${budget - spent} left this month`}
      </p>
    </div>
  );
}

function ScreenBudgets({ mode = 'light' }) {
  const cats = window.CATEGORIES;
  return (
    <Phone mode={mode} screenLabel="06 Budgets">
      <StatusBar />
      <div className="scroll" style={{ padding: '0 0 40px' }}>
        <div style={{ padding: '8px 22px 16px', display: 'flex', alignItems: 'center', gap: 16 }}>
          <Icon.chevronL size={22} weight="medium" />
          <h1 style={{ margin: 0, flex: 1, fontSize: 22, fontWeight: 600, letterSpacing: -0.3 }}>Budgets</h1>
          <Icon.plus size={22} weight="medium" color="var(--brand)" />
        </div>

        {/* Hero summary */}
        <div style={{ padding: '0 18px 18px' }}>
          <div style={{
            background: mode === 'dark' ? 'var(--surface2)' : 'var(--brand2)',
            color: '#fdf8f0', padding: 22, borderRadius: 22,
          }}>
            <p style={{ margin: 0, fontSize: 13, opacity: 0.85, letterSpacing: 0.2 }}>November budget</p>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <p className="num-hero" style={{ margin: 0, color: '#fdf8f0' }}>$1,847</p>
              <p style={{ margin: 0, fontSize: 16, opacity: 0.75 }}>of $2,400</p>
            </div>
            <div className="bar" style={{ marginTop: 14, background: 'rgba(253,248,240,0.18)' }}>
              <div style={{ width: '77%', background: '#fdf8f0' }} />
            </div>
            <p style={{ margin: '12px 0 0', fontSize: 13, opacity: 0.85 }}>$553 left · 20 days remaining</p>
          </div>
        </div>

        <div style={{ padding: '0 18px' }}>
          <BudgetRow category={cats[0]} spent={486} budget={600} mode={mode} />
          <BudgetRow category={cats[1]} spent={218} budget={200} mode={mode} />
          <BudgetRow category={cats[2]} spent={650} budget={800} mode={mode} />
          <BudgetRow category={cats[3]} spent={184} budget={250} mode={mode} />
          <BudgetRow category={cats[5]} spent={68} budget={100} mode={mode} />
          <BudgetRow category={cats[8]} spent={241} budget={250} mode={mode} />

          <div style={{
            marginTop: 6, padding: 18, borderRadius: 16,
            border: '1.5px dashed var(--text3)',
            display: 'flex', alignItems: 'center', gap: 10,
            color: 'var(--text2)', fontWeight: 500, fontSize: 14,
            justifyContent: 'center',
          }}>
            <Icon.plus size={18} color="var(--text2)" weight="medium" />
            Add a budget
          </div>
        </div>
      </div>
    </Phone>
  );
}

Object.assign(window, { ScreenWelcome, ScreenName, ScreenGroups, ScreenAIConsent, ScreenSettings, ScreenBudgets });
