/* Splitway screens — Part 2: all remaining screens
   Home, Expenses, Settle Up, Reports, Add Expense, Category Picker,
   Receipt Camera, Receipt Review, Assignment Sheet, Assistant Empty, Assistant Conversation
*/
const { Icon, StatusBar, TabBar, Fab, Avatar, Capybara, CapybaraAvatar, CapybaraGlyph, Phone } = window;

const CAT = window.CATEGORIES;

// ════════════ HOME ════════════
function ScreenHome({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="07 Home">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 120 }}>
        {/* Header */}
        <div style={{ padding: '18px 22px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <p className="serif-i" style={{ margin: 0, fontSize: 13, color: 'var(--text2)' }}>The Mahmoud House</p>
            <p style={{ margin: '4px 0 0', fontSize: 24, fontWeight: 600, letterSpacing: -0.5 }}>Good morning, Hamza</p>
          </div>
          <Avatar initials="H" idx={0} size={40} mode={mode} />
        </div>

        {/* Hero card */}
        <div style={{ padding: '0 18px 16px' }}>
          <div style={{
            background: mode === 'dark' ? 'var(--surface2)' : 'var(--brand2)',
            color: '#fdf8f0', padding: '22px 22px 18px', borderRadius: 24,
          }}>
            <p style={{ margin: 0, fontSize: 12, opacity: 0.8, letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 600 }}>This month</p>
            <p className="num-hero" style={{ margin: '6px 0 6px', color: '#fdf8f0' }}>$1,847.32</p>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, opacity: 0.92 }}>
              <Icon.arrowDownR size={14} color="#fdf8f0" weight="medium" />
              <span>$203 less than October</span>
            </div>
            <div style={{ height: 1, background: '#fdf8f0', opacity: 0.2, margin: '18px 0' }} />
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <p style={{ margin: 0, fontSize: 10.5, opacity: 0.75, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>Your balance</p>
                <p style={{ margin: '4px 0 0', fontSize: 18, fontWeight: 600, letterSpacing: -0.3 }}>You're owed <span className="num">$84</span></p>
              </div>
              <button style={{
                background: '#fdf8f0', color: 'var(--brand2)', border: 0, borderRadius: 100,
                padding: '9px 18px', fontSize: 13, fontWeight: 600, cursor: 'pointer',
              }}>Settle up</button>
            </div>
          </div>
        </div>

        {/* Budget pills */}
        <div style={{ padding: '0 18px 18px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {[
            { cat: CAT[0], spent: 486, budget: 600, pct: 81, color: 'var(--brand)' },
            { cat: CAT[1], spent: 218, budget: 200, pct: 100, color: 'var(--warn)' },
          ].map((b, i) => (
            <div key={i} className="card" style={{ padding: 14, borderRadius: 16 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <span style={{ fontSize: 12, color: 'var(--text2)', fontWeight: 600 }}>{b.cat.name}</span>
                <div style={{ width: 22, height: 22, borderRadius: 7, background: b.cat[mode].bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  {React.createElement(Icon[b.cat.icon], { size: 13, color: b.cat[mode].fg, weight: 'medium' })}
                </div>
              </div>
              <p className="num" style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>${b.spent} <span style={{ color: 'var(--text3)', fontWeight: 500 }}>/ ${b.budget}</span></p>
              <div className="bar" style={{ marginTop: 8 }}><div style={{ width: `${b.pct}%`, background: b.color }} /></div>
            </div>
          ))}
        </div>

        {/* Recent header */}
        <div style={{ padding: '0 22px 12px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <p style={{ margin: 0, fontSize: 16, fontWeight: 600, letterSpacing: -0.2 }}>Recent</p>
          <button className="btn-ghost">See all</button>
        </div>

        {/* Expense rows */}
        <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {[
            { cat: CAT[0], title: 'H-E-B groceries', meta: 'Sarah · today · 50/50', amt: 127.40, per: 63.70 },
            { cat: CAT[2], title: 'Electric bill',   meta: 'You · yesterday · 50/50', amt: 184.50, per: 92.25 },
            { cat: CAT[1], title: 'Pizza Hut',       meta: 'Ahmad · 2d ago · 4 ways', amt: 48.20, per: 12.05 },
          ].map((e, i) => (
            <div key={i} className="card" style={{ padding: 14, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
              <div className="icon-tile md" style={{ background: e.cat[mode].bg, color: e.cat[mode].fg }}>
                {React.createElement(Icon[e.cat.icon], { size: 19, weight: 'medium' })}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <p style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: -0.2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.title}</p>
                <p style={{ margin: '2px 0 0', fontSize: 12, color: 'var(--text2)' }}>{e.meta}</p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p className="num" style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>${e.amt.toFixed(2)}</p>
                <p style={{ margin: '2px 0 0', fontSize: 11, color: 'var(--text2)' }}>${e.per.toFixed(2)} each</p>
              </div>
            </div>
          ))}
        </div>
      </div>
      <Fab />
      <TabBar active="home" mode={mode} />
    </Phone>
  );
}

// ════════════ EXPENSES TAB ════════════
function ScreenExpenses({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="08 Expenses tab">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 120 }}>
        <div style={{ padding: '8px 22px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h1 className="h-large" style={{ margin: 0 }}>Expenses</h1>
          <Icon.filter size={22} weight="medium" />
        </div>

        {/* Who owes who */}
        <div style={{ padding: '0 18px 14px' }}>
          <div className="card" style={{ padding: 18, borderRadius: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
              <p style={{ margin: 0, fontSize: 14, fontWeight: 600, letterSpacing: -0.2 }}>Who owes who</p>
              <button className="btn-ghost">Settle up</button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Avatar initials="A" idx={2} size={32} mode={mode} />
                <Icon.arrowUpR size={14} color="var(--success)" weight="semibold" />
                <Avatar initials="H" idx={0} size={32} mode={mode} />
                <p style={{ margin: 0, flex: 1, fontSize: 14, color: 'var(--text1)' }}>Ahmad owes you</p>
                <p className="num" style={{ margin: 0, fontSize: 15, fontWeight: 600, color: 'var(--success)' }}>+$84.00</p>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <Avatar initials="H" idx={0} size={32} mode={mode} />
                <Icon.arrowUpR size={14} color="var(--warn)" weight="semibold" />
                <Avatar initials="S" idx={1} size={32} mode={mode} />
                <p style={{ margin: 0, flex: 1, fontSize: 14, color: 'var(--text1)' }}>You owe Sarah</p>
                <p className="num" style={{ margin: 0, fontSize: 15, fontWeight: 600, color: 'var(--warn)' }}>−$12.00</p>
              </div>
            </div>
          </div>
        </div>

        {/* Filter pills */}
        <div style={{ padding: '0 18px 14px', display: 'flex', gap: 8, overflowX: 'auto' }}>
          <span className="chip" data-active="true">November</span>
          <span className="chip">Category</span>
          <span className="chip">Person</span>
          <span className="chip">Group</span>
        </div>

        {/* Date groups */}
        {[
          { date: 'Today', items: [{ cat: CAT[0], t: 'H-E-B groceries', meta: 'Sarah · 50/50', a: 127.40, you: -63.70 }] },
          { date: 'Yesterday', items: [
            { cat: CAT[2], t: 'Electric bill', meta: 'You · 50/50', a: 184.50, you: 92.25 },
            { cat: CAT[5], t: 'Netflix', meta: 'You · 4 ways', a: 15.99, you: -4.00, excluded: false },
          ]},
          { date: 'Nov 8', items: [
            { cat: CAT[1], t: 'Pizza Hut', meta: 'Ahmad · 4 ways', a: 48.20, you: -12.05 },
            { cat: CAT[7], t: 'Face wash', meta: 'You · personal', a: 12.00, excluded: true },
          ]},
        ].map((g, gi) => (
          <div key={gi} style={{ padding: '0 18px' }}>
            <p style={{ margin: '6px 4px 8px', fontSize: 13, color: 'var(--text2)', fontWeight: 600 }}>{g.date}</p>
            <div className="card" style={{ borderRadius: 16, overflow: 'hidden', marginBottom: 14 }}>
              {g.items.map((e, i) => (
                <React.Fragment key={i}>
                  <div style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div className="icon-tile sm" style={{ background: e.cat[mode].bg, color: e.cat[mode].fg }}>
                      {React.createElement(Icon[e.cat.icon], { size: 17, weight: 'medium' })}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <p style={{ margin: 0, fontSize: 14.5, fontWeight: 600, letterSpacing: -0.2 }}>{e.t}</p>
                      <p style={{ margin: '2px 0 0', fontSize: 11.5, color: 'var(--text2)' }}>{e.meta}</p>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <p className="num" style={{ margin: 0, fontSize: 14.5, fontWeight: 600 }}>${e.a.toFixed(2)}</p>
                      <p className="num" style={{ margin: '2px 0 0', fontSize: 11, fontWeight: 600,
                                                  color: e.excluded ? 'var(--text3)' : e.you > 0 ? 'var(--success)' : 'var(--warn)' }}>
                        {e.excluded ? 'excluded' : (e.you > 0 ? '+' : '') + '$' + Math.abs(e.you).toFixed(2)}
                      </p>
                    </div>
                  </div>
                  {i < g.items.length - 1 && <div className="row-sep" />}
                </React.Fragment>
              ))}
            </div>
          </div>
        ))}
      </div>
      <Fab />
      <TabBar active="expenses" mode={mode} />
    </Phone>
  );
}

// ════════════ SETTLE UP ════════════
function ScreenSettle({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="09 Settle up">
      <StatusBar />
      <div className="scroll" style={{ padding: '0 0 40px' }}>
        <div style={{ padding: '8px 22px 14px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <Icon.chevronL size={22} weight="medium" />
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 600, letterSpacing: -0.3 }}>Settle up</h1>
        </div>

        <div style={{ padding: '0 18px' }}>
          <div style={{ padding: '18px 4px 14px' }}>
            <p className="serif-i" style={{ margin: 0, fontSize: 22, lineHeight: 1.2 }}>The simplest way</p>
            <p style={{ margin: '6px 0 0', fontSize: 14, color: 'var(--text2)' }}>Just 2 payments to settle everyone up.</p>
          </div>

          {[
            { from: { i: 'A', idx: 2, n: 'Ahmad' }, to: { i: 'H', idx: 0, n: 'You' }, amt: 71.80 },
            { from: { i: 'M', idx: 3, n: 'Sumaya' }, to: { i: 'S', idx: 1, n: 'Sarah' }, amt: 24.50 },
          ].map((p, i) => (
            <div key={i} className="card" style={{ padding: 18, borderRadius: 18, marginBottom: 12 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, marginBottom: 14 }}>
                <Avatar initials={p.from.i} idx={p.from.idx} size={44} mode={mode} />
                <div style={{ flex: '0 0 auto', display: 'flex', alignItems: 'center', gap: 4 }}>
                  <div style={{ width: 30, height: 1.5, background: 'var(--text3)' }} />
                  <Icon.chevronR size={14} color="var(--text3)" weight="semibold" />
                </div>
                <Avatar initials={p.to.i} idx={p.to.idx} size={44} mode={mode} />
              </div>
              <p style={{ margin: 0, textAlign: 'center', fontSize: 14, color: 'var(--text2)' }}>
                <strong style={{ color: 'var(--text1)', fontWeight: 600 }}>{p.from.n}</strong> pays{' '}
                <strong style={{ color: 'var(--text1)', fontWeight: 600 }}>{p.to.n}</strong>
              </p>
              <p className="num-hero" style={{ margin: '4px 0 16px', textAlign: 'center', fontSize: 30 }}>${p.amt.toFixed(2)}</p>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn-primary" style={{ flex: 1, padding: '12px 14px', fontSize: 14 }}>Mark paid</button>
                <button className="btn-secondary" style={{ flex: 1, padding: '11px 14px', fontSize: 14, borderColor: 'var(--text3)' }}>Open Zelle</button>
              </div>
            </div>
          ))}

          {/* explainer */}
          <div style={{ background: 'var(--successSoft)', padding: 18, borderRadius: 18, marginTop: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <Icon.info size={18} color="var(--success)" weight="medium" />
              <p style={{ margin: 0, fontSize: 14, fontWeight: 600, color: 'var(--success)' }}>How this works</p>
            </div>
            <p style={{ margin: 0, fontSize: 13, color: 'var(--success)', lineHeight: 1.5 }}>
              Ahmad owes you $84, but you owe Sarah $12. Instead of three transactions, Ahmad pays you $71.80
              — the math nets out the same.
            </p>
          </div>

          <button className="btn-ghost" style={{ width: '100%', padding: '18px 0', marginTop: 10 }}>
            Show all transactions instead
          </button>
        </div>
      </div>
    </Phone>
  );
}

// ════════════ REPORTS ════════════
function ScreenReports({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="10 Reports">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 120 }}>
        <div style={{ padding: '8px 22px 8px' }}>
          <h1 className="h-large" style={{ margin: 0 }}>Reports</h1>
        </div>

        {/* Month picker */}
        <div style={{ padding: '6px 22px 14px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16 }}>
          <Icon.chevronL size={18} color="var(--text2)" weight="medium" />
          <p style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>November 2025</p>
          <Icon.chevronR size={18} color="var(--text2)" weight="medium" />
        </div>

        {/* Hero total */}
        <div style={{ padding: '0 18px 14px' }}>
          <div style={{ background: mode === 'dark' ? 'var(--surface2)' : 'var(--brand2)', color: '#fdf8f0', padding: 22, borderRadius: 22 }}>
            <p style={{ margin: 0, fontSize: 11.5, opacity: 0.8, letterSpacing: 0.4, textTransform: 'uppercase', fontWeight: 600 }}>Household spent</p>
            <p className="num-hero" style={{ margin: '6px 0 6px', color: '#fdf8f0' }}>$1,847.32</p>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, opacity: 0.92 }}>
              <Icon.arrowDownR size={14} color="#fdf8f0" weight="medium" />
              <span>9.9% less than October</span>
            </div>
          </div>
        </div>

        {/* Pie */}
        <div style={{ padding: '0 18px 14px' }}>
          <div className="card" style={{ padding: 18, borderRadius: 20 }}>
            <p style={{ margin: '0 0 14px', fontSize: 14, fontWeight: 600, letterSpacing: -0.2 }}>By category</p>
            <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
              <svg width="120" height="120" viewBox="0 0 120 120">
                {/* donut: 4 segments */}
                <circle cx="60" cy="60" r="46" fill="none" stroke="var(--brand)" strokeWidth="20" strokeDasharray="115 289" />
                <circle cx="60" cy="60" r="46" fill="none" stroke="var(--warn)" strokeWidth="20" strokeDasharray="80 289" strokeDashoffset="-115" />
                <circle cx="60" cy="60" r="46" fill="none" stroke="var(--brand2)" strokeWidth="20" strokeDasharray="56 289" strokeDashoffset="-195" />
                <circle cx="60" cy="60" r="46" fill="none" stroke="var(--success)" strokeWidth="20" strokeDasharray="38 289" strokeDashoffset="-251" />
                <text x="60" y="58" textAnchor="middle" fontSize="13" fill="var(--text2)">Total</text>
                <text x="60" y="74" textAnchor="middle" fontSize="16" fontWeight="600" fill="var(--text1)">$1,847</text>
              </svg>
              <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
                {[
                  { c: 'var(--brand)', n: 'Groceries', a: 486 },
                  { c: 'var(--warn)', n: 'Dining', a: 218 },
                  { c: 'var(--brand2)', n: 'Housing', a: 650 },
                  { c: 'var(--success)', n: 'Utilities', a: 184 },
                ].map((l, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5 }}>
                    <div style={{ width: 8, height: 8, borderRadius: 2, background: l.c }} />
                    <span style={{ flex: 1, color: 'var(--text2)' }}>{l.n}</span>
                    <span className="num" style={{ fontWeight: 600 }}>${l.a}</span>
                  </div>
                ))}
              </div>
            </div>
            <button className="btn-ghost" style={{ marginTop: 12 }}>View all categories</button>
          </div>
        </div>

        {/* Trend */}
        <div style={{ padding: '0 18px 14px' }}>
          <div className="card" style={{ padding: 18, borderRadius: 20 }}>
            <p style={{ margin: '0 0 14px', fontSize: 14, fontWeight: 600, letterSpacing: -0.2 }}>6-month trend</p>
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 90 }}>
              {[68, 82, 75, 88, 92, 77].map((h, i) => (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                  <div style={{ width: '100%', height: `${h}%`, background: i === 5 ? 'var(--brand)' : 'var(--surface2)', borderRadius: 6 }} />
                  <span style={{ fontSize: 10, color: 'var(--text2)' }}>{['Jun','Jul','Aug','Sep','Oct','Nov'][i]}</span>
                </div>
              ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 14, paddingTop: 14, borderTop: '0.5px solid var(--divider)' }}>
              <div><p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>Monthly avg</p><p className="num" style={{ margin: '2px 0 0', fontWeight: 600 }}>$1,938</p></div>
              <div><p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>vs Oct</p><p className="num" style={{ margin: '2px 0 0', fontWeight: 600, color: 'var(--success)' }}>−9.9%</p></div>
            </div>
          </div>
        </div>

        {/* Top expenses */}
        <div style={{ padding: '0 18px 16px' }}>
          <div className="card" style={{ padding: 18, borderRadius: 20 }}>
            <p style={{ margin: '0 0 14px', fontSize: 14, fontWeight: 600, letterSpacing: -0.2 }}>Top expenses</p>
            {[
              { c: CAT[2], t: 'Rent', d: 'Nov 1 · 50/50', a: 2400 },
              { c: CAT[2], t: 'Electric bill', d: 'Nov 9 · 50/50', a: 184.50 },
              { c: CAT[0], t: 'H-E-B (big haul)', d: 'Nov 10 · per item', a: 127.40 },
            ].map((e, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 0', borderBottom: i < 2 ? '0.5px solid var(--divider)' : 0 }}>
                <div className="icon-tile sm" style={{ background: e.c[mode].bg, color: e.c[mode].fg }}>
                  {React.createElement(Icon[e.c.icon], { size: 16, weight: 'medium' })}
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ margin: 0, fontSize: 14, fontWeight: 600 }}>{e.t}</p>
                  <p style={{ margin: '2px 0 0', fontSize: 11.5, color: 'var(--text2)' }}>{e.d}</p>
                </div>
                <p className="num" style={{ margin: 0, fontSize: 14, fontWeight: 600 }}>${e.a.toFixed(2)}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
      <TabBar active="reports" mode={mode} />
    </Phone>
  );
}

// ════════════ ADD EXPENSE ════════════
function ScreenAddExpense({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="11 Add expense">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 30 }}>
        {/* top bar */}
        <div style={{ padding: '12px 22px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Icon.close size={22} weight="medium" />
          <p style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>New expense</p>
          <Icon.camera size={22} weight="medium" color="var(--brand)" />
        </div>

        {/* Amount hero */}
        <div style={{ padding: '24px 22px 18px', textAlign: 'center' }}>
          <p className="eyebrow" style={{ margin: 0 }}>Amount</p>
          <p style={{ margin: '10px 0 0', fontSize: 56, lineHeight: 1, fontWeight: 500, letterSpacing: -1.5, fontVariantNumeric: 'tabular-nums' }}>
            <span style={{ color: 'var(--text3)', fontSize: 36 }}>$</span>127.40
          </p>
        </div>

        {/* Fields */}
        <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {/* Category */}
          <div className="card" style={{ padding: 14, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className="icon-tile sm" style={{ background: CAT[0][mode].bg, color: CAT[0][mode].fg }}>
              <Icon.cart size={17} weight="medium" />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>Category</p>
              <p style={{ margin: '1px 0 0', fontSize: 15, fontWeight: 600 }}>Groceries</p>
            </div>
            <Icon.chevronR size={16} color="var(--text3)" weight="medium" />
          </div>

          {/* Description */}
          <div className="card" style={{ padding: 14, borderRadius: 16 }}>
            <p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>Description</p>
            <p style={{ margin: '1px 0 0', fontSize: 15, fontWeight: 600 }}>H-E-B groceries</p>
          </div>

          {/* Date */}
          <div className="card" style={{ padding: 14, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
            <Icon.calendar size={18} color="var(--brand)" weight="medium" />
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>Date</p>
              <p style={{ margin: '1px 0 0', fontSize: 15, fontWeight: 600 }}>Today, Nov 10</p>
            </div>
            <Icon.chevronR size={16} color="var(--text3)" weight="medium" />
          </div>

          {/* Split */}
          <div className="card" style={{ padding: 16, borderRadius: 16 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
              <p style={{ margin: 0, fontSize: 13, color: 'var(--text2)', fontWeight: 600 }}>Split</p>
              <button className="btn-ghost" style={{ fontSize: 12 }}>Customize</button>
            </div>
            <div className="pill-group" style={{ marginBottom: 14 }}>
              <div className="pill" data-active="true">Equal</div>
              <div className="pill">%</div>
              <div className="pill">$</div>
              <div className="pill">Shares</div>
              <div className="pill">Excluded</div>
            </div>
            {[
              { i: 'MF', idx: 1, n: 'Mahmoud family', sub: 'Hamza, Sarah', amt: 63.70 },
              { i: 'HF', idx: 0, n: 'Hassan family', sub: 'Ahmad, Sumaya', amt: 63.70 },
            ].map((m, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0' }}>
                <Avatar initials={m.i} idx={m.idx} size={30} mode={mode} />
                <div style={{ flex: 1 }}>
                  <p style={{ margin: 0, fontSize: 14, fontWeight: 600 }}>{m.n}</p>
                  <p style={{ margin: '1px 0 0', fontSize: 11, color: 'var(--text2)' }}>{m.sub}</p>
                </div>
                <p className="num" style={{ margin: 0, fontSize: 14, fontWeight: 600 }}>${m.amt.toFixed(2)}</p>
              </div>
            ))}
          </div>

          {/* Paid by */}
          <div className="card" style={{ padding: 14, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
            <Icon.wallet size={18} color="var(--brand)" weight="medium" />
            <div style={{ flex: 1 }}>
              <p style={{ margin: 0, fontSize: 11, color: 'var(--text2)' }}>Paid by</p>
              <p style={{ margin: '1px 0 0', fontSize: 15, fontWeight: 600 }}>Sarah</p>
            </div>
            <Icon.chevronR size={16} color="var(--text3)" weight="medium" />
          </div>
        </div>

        <div style={{ padding: '20px 22px 16px' }}>
          <button className="btn-primary">Save expense</button>
        </div>
      </div>
    </Phone>
  );
}

// ════════════ CATEGORY PICKER ════════════
function ScreenCategory({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="12 Category picker">
      <StatusBar />
      <div className="scroll" style={{ padding: '0 0 30px' }}>
        <div style={{ padding: '8px 22px 14px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <Icon.chevronL size={22} weight="medium" />
          <h1 style={{ margin: 0, fontSize: 22, fontWeight: 600, letterSpacing: -0.3 }}>Choose category</h1>
        </div>

        {/* Search */}
        <div style={{ padding: '0 18px 14px' }}>
          <div style={{ background: 'var(--surface2)', borderRadius: 12, padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Icon.search size={17} color="var(--text2)" weight="medium" />
            <span style={{ color: 'var(--text3)', fontSize: 15 }}>Search</span>
          </div>
        </div>

        <div style={{ padding: '0 18px' }}>
          <div className="card" style={{ borderRadius: 16, overflow: 'hidden' }}>
            {CAT.map((c, i) => (
              <React.Fragment key={c.id}>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
                  background: i === 0 ? 'var(--brandSoft)' : 'transparent',
                }}>
                  <div className="icon-tile sm" style={{ background: c[mode].bg, color: c[mode].fg }}>
                    {React.createElement(Icon[c.icon], { size: 18, weight: 'medium' })}
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>{c.name}</p>
                    {i === 0 && <p style={{ margin: '2px 0 0', fontSize: 11.5, color: 'var(--text2)' }}>$486 of $600 this month</p>}
                  </div>
                  {i === 0 && <Icon.check size={18} color="var(--brand)" weight="semibold" />}
                </div>
                {i < CAT.length - 1 && <div className="row-sep" />}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ════════════ RECEIPT CAMERA ════════════
function ScreenReceiptCamera({ mode = 'light' }) {
  return (
    <Phone mode="dark" screenLabel="13 Receipt camera">
      <div style={{ position: 'absolute', inset: 0, background: '#0a0805' }}>
        {/* fake viewfinder */}
        <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, #1a1108 0%, #0a0805 50%, #1a1108 100%)' }} />
        {/* receipt placeholder behind frame */}
        <div style={{
          position: 'absolute', top: 180, left: 70, right: 70, bottom: 220,
          background: 'linear-gradient(180deg, #f5ede0 0%, #e8dcc8 100%)',
          opacity: 0.85, borderRadius: 4,
          backgroundImage: 'repeating-linear-gradient(0deg, transparent 0, transparent 12px, rgba(42,29,20,0.15) 12px, rgba(42,29,20,0.15) 13px)',
        }} />
      </div>
      <StatusBar color="#fff" />

      {/* Top bar */}
      <div style={{ position: 'absolute', top: 56, left: 0, right: 0, padding: '8px 22px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', zIndex: 10 }}>
        <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(20px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon.close size={20} color="#fff" weight="medium" />
        </div>
        <p style={{ margin: 0, color: '#fff', fontSize: 16, fontWeight: 600 }}>Scan receipt</p>
        <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(20px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon.flash size={18} color="#fff" weight="medium" />
        </div>
      </div>

      {/* Frame with orange corner brackets */}
      <div style={{ position: 'absolute', top: 170, left: 56, right: 56, bottom: 200, pointerEvents: 'none' }}>
        <div style={{ position: 'absolute', inset: 0, border: '1.5px solid #f29545', borderRadius: 8, opacity: 0.55 }} />
        {/* corner brackets */}
        {[
          { t: -2, l: -2, br: '14px 0 0 0', ws: 'top left' },
          { t: -2, r: -2, br: '0 14px 0 0', ws: 'top right' },
          { b: -2, l: -2, br: '0 0 0 14px', ws: 'bottom left' },
          { b: -2, r: -2, br: '0 0 14px 0', ws: 'bottom right' },
        ].map((c, i) => (
          <div key={i} style={{
            position: 'absolute', top: c.t, left: c.l, right: c.r, bottom: c.b,
            width: 34, height: 34,
            borderTop: c.t !== undefined ? '4px solid #f29545' : 0,
            borderBottom: c.b !== undefined ? '4px solid #f29545' : 0,
            borderLeft: c.l !== undefined ? '4px solid #f29545' : 0,
            borderRight: c.r !== undefined ? '4px solid #f29545' : 0,
            borderRadius: c.br,
          }} />
        ))}
      </div>

      {/* Instruction banner */}
      <div style={{ position: 'absolute', top: 130, left: 0, right: 0, display: 'flex', justifyContent: 'center', zIndex: 10 }}>
        <div style={{ background: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(20px)', padding: '8px 16px', borderRadius: 100 }}>
          <p style={{ margin: 0, color: '#fff', fontSize: 13, fontWeight: 500 }}>Position receipt inside the frame</p>
        </div>
      </div>

      {/* Bottom controls */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '30px 40px 60px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', zIndex: 10 }}>
        <div style={{ width: 44, height: 44, borderRadius: 10, background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(20px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon.bag size={20} color="#fff" weight="medium" />
        </div>
        <div style={{ width: 72, height: 72, borderRadius: '50%', background: '#fff', border: '4px solid rgba(255,255,255,0.3)', boxShadow: '0 0 0 1px rgba(255,255,255,0.5)' }} />
        <div style={{ width: 44, height: 44, borderRadius: 10, background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(20px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Icon.arrowUpR size={20} color="#fff" weight="medium" />
        </div>
      </div>
    </Phone>
  );
}

// ════════════ RECEIPT REVIEW ════════════
function ScreenReceiptReview({ mode = 'light' }) {
  const items = [
    { name: 'Whole milk gallon',    status: 'known', label: 'Shared 50/50',    price: 4.89 },
    { name: 'Eggs (dozen)',          status: 'known', label: 'Shared 50/50',    price: 5.49 },
    { name: 'Greek yogurt',          status: 'known', label: 'Shared 50/50',    price: 6.99 },
    { name: 'Coffee beans 12oz',    status: 'known', label: 'Shared 50/50',    price: 14.99 },
    { name: 'Cherry Coke 6-pack',   status: 'new',   label: 'New · tap to assign', price: 7.49 },
    { name: 'Face wash',             status: 'new',   label: 'New · tap to assign', price: 12.00 },
    { name: 'Apples (3 lb bag)',    status: 'known', label: 'Shared 50/50',    price: 5.97 },
  ];
  return (
    <Phone mode={mode} screenLabel="14 Receipt review">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 90 }}>
        <div style={{ padding: '8px 22px 6px', display: 'flex', alignItems: 'center', gap: 14 }}>
          <Icon.chevronL size={22} weight="medium" />
          <h1 style={{ margin: 0, flex: 1, fontSize: 22, fontWeight: 600, letterSpacing: -0.3 }}>Review items</h1>
          <Icon.edit size={20} weight="medium" color="var(--brand)" />
        </div>
        <p style={{ margin: '0 22px 14px', fontSize: 13, color: 'var(--text2)' }}>H-E-B · Nov 10 · $127.40</p>

        {/* Recognition banner */}
        <div style={{ padding: '0 18px 14px' }}>
          <div style={{ background: 'var(--successSoft)', padding: 14, borderRadius: 14, display: 'flex', gap: 10 }}>
            <Icon.sparkle size={18} color="var(--success)" weight="medium" style={{ flexShrink: 0, marginTop: 1 }} />
            <p style={{ margin: 0, fontSize: 13, color: 'var(--success)', lineHeight: 1.45, fontWeight: 500 }}>
              I recognized <b>5 items</b> from past receipts. Review <b>2 new items</b> below.
            </p>
          </div>
        </div>

        {/* Items */}
        <div style={{ padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {items.map((item, i) => {
            const isNew = item.status === 'new';
            return (
              <div key={i} className="card" style={{
                padding: '14px 16px', borderRadius: 14,
                borderLeft: `4px solid ${isNew ? 'var(--warn)' : 'var(--success)'}`,
                display: 'flex', alignItems: 'center', gap: 12,
              }}>
                {isNew
                  ? <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'var(--warnSoft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Icon.q size={14} color="var(--warn)" weight="semibold" />
                    </div>
                  : <div style={{ width: 22, height: 22, borderRadius: '50%', background: 'var(--successSoft)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <Icon.check size={14} color="var(--success)" weight="semibold" />
                    </div>}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <p style={{ margin: 0, fontSize: 14.5, fontWeight: 600, letterSpacing: -0.2 }}>{item.name}</p>
                  <p style={{ margin: '2px 0 0', fontSize: 11.5, color: isNew ? 'var(--warn)' : 'var(--text2)', fontWeight: isNew ? 600 : 400 }}>{item.label}</p>
                </div>
                <p className="num" style={{ margin: 0, fontSize: 14.5, fontWeight: 600 }}>${item.price.toFixed(2)}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Bottom CTA */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '16px 22px 36px', background: 'linear-gradient(180deg, transparent, var(--bg) 30%)' }}>
        <button className="btn-primary" disabled style={{ opacity: 0.5 }}>Continue to split · 2 items left</button>
      </div>
    </Phone>
  );
}

// ════════════ ASSIGNMENT SHEET ════════════
function ScreenAssignmentSheet({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="15 Assignment sheet">
      <StatusBar />
      {/* Dimmed background showing receipt review */}
      <div style={{ flex: 1, background: 'rgba(0,0,0,0.45)', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
        <div style={{
          background: 'var(--bg)', borderRadius: '24px 24px 0 0',
          padding: '8px 0 36px', boxShadow: '0 -10px 30px rgba(0,0,0,0.18)',
        }}>
          {/* drag handle */}
          <div style={{ width: 38, height: 5, background: 'var(--text3)', borderRadius: 100, margin: '8px auto 16px' }} />

          {/* item header */}
          <div style={{ padding: '0 22px 12px' }}>
            <p className="eyebrow" style={{ margin: 0 }}>New item</p>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginTop: 6 }}>
              <p style={{ margin: 0, fontSize: 19, fontWeight: 600, letterSpacing: -0.3 }}>Cherry Coke 6-pack</p>
              <p className="num" style={{ margin: 0, fontSize: 17, fontWeight: 600 }}>$7.49</p>
            </div>
            <p style={{ margin: '6px 0 0', fontSize: 13, color: 'var(--text2)' }}>Who's this for?</p>
          </div>

          {/* options */}
          <div style={{ padding: '6px 18px', display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { i: '◉', n: 'Shared between all', sub: '$1.87 each · 4 people', selected: false },
              { i: 'H', idx: 0, n: 'Just Hamza',  sub: '', selected: true },
              { i: 'S', idx: 1, n: 'Just Sarah',  sub: '', selected: false },
              { i: 'A', idx: 2, n: 'Just Ahmad',  sub: '', selected: false },
              { i: 'M', idx: 3, n: 'Just Sumaya', sub: '', selected: false },
            ].map((o, i) => (
              <div key={i} className="card" style={{
                padding: 14, borderRadius: 14, display: 'flex', alignItems: 'center', gap: 12,
                border: o.selected ? '1.5px solid var(--brand)' : '1.5px solid transparent',
              }}>
                {o.i === '◉'
                  ? <div className="icon-tile sm" style={{ background: 'var(--surface2)', color: 'var(--text2)' }}>
                      <Icon.users size={17} weight="medium" />
                    </div>
                  : <Avatar initials={o.i} idx={o.idx} size={32} mode={mode} />}
                <div style={{ flex: 1 }}>
                  <p style={{ margin: 0, fontSize: 14.5, fontWeight: 600 }}>{o.n}</p>
                  {o.sub && <p style={{ margin: '2px 0 0', fontSize: 11.5, color: 'var(--text2)' }}>{o.sub}</p>}
                </div>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: o.selected ? 'var(--brand)' : 'transparent',
                  border: o.selected ? 0 : '2px solid var(--text3)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {o.selected && <Icon.check size={13} color="var(--cta-text)" weight="semibold" />}
                </div>
              </div>
            ))}
          </div>

          {/* Remember dropdown */}
          <div style={{ padding: '14px 18px 16px' }}>
            <div className="card" style={{ padding: 14, borderRadius: 14, background: 'var(--surface2)' }}>
              <p style={{ margin: 0, fontSize: 11.5, color: 'var(--text2)', fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase' }}>Remember</p>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 }}>
                <p style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>Always Hamza's</p>
                <Icon.chevronD size={18} color="var(--text2)" weight="medium" />
              </div>
            </div>
          </div>

          <div style={{ padding: '0 22px' }}>
            <button className="btn-primary">Confirm</button>
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ════════════ ASSISTANT EMPTY ════════════
function ScreenAssistantEmpty({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="16 Assistant empty">
      <StatusBar />
      <div className="scroll" style={{ paddingBottom: 200 }}>
        <div style={{ padding: '24px 22px 12px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
          <Capybara size={170} state="idle" />
          <div>
            <p className="serif-i" style={{ margin: 0, fontSize: 24, color: 'var(--text1)' }}>Hi, I'm your assistant</p>
            <p style={{ margin: '6px 24px 0', fontSize: 14, color: 'var(--text2)', lineHeight: 1.5 }}>
              Ask me anything about your household's spending
            </p>
          </div>
        </div>

        <div style={{ padding: '12px 18px 0' }}>
          <p className="eyebrow" style={{ margin: '6px 4px 12px' }}>Try asking</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { i: 'trend',         t: 'How much did we spend on groceries this month?' },
              { i: 'users',         t: 'Did I pay Ahmad back yet?' },
              { i: 'bell',          t: 'Are we over budget on anything?' },
              { i: 'calendar',      t: 'Compare this month to last month' },
            ].map((q, i) => (
              <div key={i} className="card" style={{ padding: '14px 16px', borderRadius: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
                {React.createElement(Icon[q.i], { size: 18, color: 'var(--brand)', weight: 'medium' })}
                <p style={{ margin: 0, flex: 1, fontSize: 13.5, color: 'var(--text1)', lineHeight: 1.4 }}>{q.t}</p>
                <Icon.arrowUpR size={14} color="var(--text3)" weight="medium" />
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Input bar */}
      <div style={{ position: 'absolute', bottom: 100, left: 16, right: 16, zIndex: 30 }}>
        <div className="card" style={{
          borderRadius: 100, padding: '5px 6px 5px 18px', display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span style={{ flex: 1, color: 'var(--text3)', fontSize: 14 }}>Ask something…</span>
          <div style={{ width: 38, height: 38, borderRadius: '50%', background: 'var(--cta)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon.arrowUp size={18} color="var(--cta-text)" weight="semibold" />
          </div>
        </div>
        <p style={{ margin: '8px 0 0', fontSize: 10.5, color: 'var(--text3)', textAlign: 'center' }}>
          Powered by Claude · Your data stays private
        </p>
      </div>
      <TabBar active="assistant" mode={mode} />
    </Phone>
  );
}

// ════════════ ASSISTANT CONVERSATION ════════════
function ScreenAssistantChat({ mode = 'light' }) {
  return (
    <Phone mode={mode} screenLabel="17 Assistant chat">
      <StatusBar />
      {/* Chat header */}
      <div style={{ padding: '8px 18px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <CapybaraAvatar size={36} mode={mode} />
        <div style={{ flex: 1 }}>
          <p style={{ margin: 0, fontSize: 15, fontWeight: 600 }}>Assistant</p>
          <p style={{ margin: '2px 0 0', fontSize: 11, color: 'var(--success)', fontWeight: 500, display: 'flex', alignItems: 'center', gap: 5 }}>
            <span className="dot" />Ready
          </p>
        </div>
        <Icon.dots size={20} weight="medium" color="var(--text2)" />
      </div>

      <div className="scroll" style={{ padding: '4px 18px 8px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {/* User question */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            background: 'var(--cta)', color: 'var(--cta-text)',
            padding: '11px 15px', borderRadius: '20px 20px 6px 20px',
            maxWidth: '76%', fontSize: 14.5, lineHeight: 1.4, letterSpacing: -0.2,
          }}>How much on groceries this month?</div>
        </div>

        {/* Assistant response */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <CapybaraAvatar size={24} mode={mode} />
          <div className="card" style={{
            padding: '13px 16px', borderRadius: '20px 20px 20px 6px',
            maxWidth: '78%', fontSize: 14, lineHeight: 1.5,
          }}>
            You've spent <b>$486 on groceries</b> in November so far — that's $114 under your $600 budget with 20 days left.
            <div style={{ height: 0.5, background: 'var(--divider)', margin: '10px 0' }} />
            <p style={{ margin: 0, fontSize: 11.5, color: 'var(--text2)', fontWeight: 600, letterSpacing: 0.3, textTransform: 'uppercase' }}>By store</p>
            <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
              {[['H-E-B', 312], ['Costco', 128], ['Whole Foods', 46]].map(([s, a], i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
                  <span>{s}</span><span className="num" style={{ fontWeight: 600 }}>${a}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* User follow-up */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            background: 'var(--cta)', color: 'var(--cta-text)',
            padding: '11px 15px', borderRadius: '20px 20px 6px 20px',
            maxWidth: '76%', fontSize: 14.5, lineHeight: 1.4, letterSpacing: -0.2,
          }}>Did I pay Ahmad back?</div>
        </div>

        {/* Thinking state */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <CapybaraAvatar size={24} mode={mode} />
          <div className="card" style={{ padding: '13px 16px', borderRadius: '20px 20px 20px 6px', display: 'flex', gap: 4 }}>
            {[0,1,2].map(i => <span key={i} style={{
              width: 6, height: 6, borderRadius: '50%', background: 'var(--text3)',
              animation: `dotBounce 1.2s ease-in-out ${i*0.15}s infinite`,
            }} />)}
            <style>{`@keyframes dotBounce { 0%,80%,100% { opacity:0.3; transform: translateY(0); } 40% { opacity:1; transform: translateY(-3px); } }`}</style>
          </div>
        </div>
      </div>

      {/* Input bar */}
      <div style={{ position: 'absolute', bottom: 100, left: 16, right: 16, zIndex: 30 }}>
        <div className="card" style={{ borderRadius: 100, padding: '5px 6px 5px 18px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ flex: 1, color: 'var(--text3)', fontSize: 14 }}>Ask something…</span>
          <div style={{ width: 38, height: 38, borderRadius: '50%', background: 'var(--cta)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon.arrowUp size={18} color="var(--cta-text)" weight="semibold" />
          </div>
        </div>
      </div>
      <TabBar active="assistant" mode={mode} />
    </Phone>
  );
}

Object.assign(window, {
  ScreenHome, ScreenExpenses, ScreenSettle, ScreenReports,
  ScreenAddExpense, ScreenCategory, ScreenReceiptCamera, ScreenReceiptReview, ScreenAssignmentSheet,
  ScreenAssistantEmpty, ScreenAssistantChat,
});
