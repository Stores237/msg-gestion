const DS = window.KawloSpekoohDesignSystem_10ffa8;
function lucideNode(n, k) { if (!Array.isArray(n) || typeof n[0] !== 'string') return null; const [tag, attrs, kids] = n; return React.createElement(tag, { key: k, ...(attrs || {}) }, Array.isArray(kids) ? kids.map(lucideNode) : null); }
function I({ name, size = 20, style }) {
  const pascal = name.replace(/(^\w|-\w)/g, m => m.replace('-', '').toUpperCase());
  let nodes = (window.lucide && window.lucide.icons && window.lucide.icons[pascal]) || [];
  if (nodes[0] === 'svg') nodes = nodes[2] || [];
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, ...style }} aria-hidden="true">{nodes.map(lucideNode)}</svg>;
}
const NB = '\u202F';
const fmt = n => String(Math.abs(n)).replace(/\B(?=(\d{3})+(?!\d))/g, NB);
function Amt({ v, sign, size, tone, weight = 700 }) {
  const s = sign ? (v < 0 ? '−\u2009' : '+\u2009') : (v < 0 ? '−\u2009' : '');
  return <span className="tnum" style={{ fontWeight: weight, fontSize: size, color: tone ? `var(--${tone})` : undefined, whiteSpace: 'nowrap' }}>{s}{fmt(v)}<span className="amt-cur">{'\u00A0'}FCFA</span></span>;
}
const TAB_DEF = { accueil: ['house', 'Accueil'], membres: ['users', 'Membres'], finances: ['wallet', 'Finances'], calendrier: ['calendar', 'Calendrier'], annonces: ['megaphone', 'Annonces'] };
const ROLE_TABS = {
  membre: ['accueil', 'calendrier', 'annonces'],
  censeur: ['accueil', 'membres', 'calendrier', 'annonces'],
  sg: ['accueil', 'membres', 'calendrier', 'annonces'],
  tresorier: ['accueil', 'membres', 'finances', 'calendrier', 'annonces'],
  cac: ['accueil', 'membres', 'finances', 'calendrier', 'annonces'],
  president: ['accueil', 'membres', 'finances', 'calendrier', 'annonces'],
};
const STATUS = { actif: ['green', 'Actif'], conge: ['amber', 'En congé'], classe: ['neutral', 'Classé'] };

function StatusBar({ net = 'ok' }) {
  return <div className="sbar"><span className="tnum">14:32</span><span>{net === 'offline' ? <I name="wifi-off" size={14} /> : <I name="signal" size={14} />}<I name="battery-medium" size={16} /></span></div>;
}
function Phone({ label, note, role, active, children, overlay, net, toast, tall }) {
  const keys = role ? ROLE_TABS[role] : null;
  return <figure className="shot" data-screen-label={label}>
    <div className={'phone' + (tall ? ' tall' : '')}><StatusBar net={net} /><div className="phone-body">{children}</div>
      {keys && <div className="msg-tabbar"><DS.BottomNav items={keys.map(k => ({ icon: <I name={TAB_DEF[k][0]} size={22} />, label: TAB_DEF[k][1] }))} active={keys.indexOf(active)} onChange={() => { }} /></div>}
      {toast}{overlay}</div>
    <figcaption><b>{label}</b>{note && <span>{note}</span>}</figcaption></figure>;
}
function LogoSlot({ size = 40, label = 'LOGO' }) {
  return <div className="logo-slot" style={{ width: size, height: size, borderRadius: size > 60 ? 24 : 12 }} title="Emplacement du logo (fourni plus tard)">{size >= 64 && <I name="image" size={size / 4} />}{label}</div>;
}
function IconBtn({ icon, label, dot, boxed }) {
  return <button className={'iconbtn' + (boxed ? ' boxed' : '')} aria-label={label}><I name={icon} size={22} />{dot && <span className="dot" />}</button>;
}
const SYNC = {
  ok: ['check', 'Synchronisé · dernière synchronisation 14:32'],
  syncing: ['refresh-cw', 'Synchronisation en cours…'],
  offline: ['cloud-off', 'Hors ligne · dernière synchronisation hier, 18:05'],
  error: ['triangle-alert', 'Échec de la synchronisation'],
};
function SyncLine({ state = 'ok', text }) {
  const [ic, t] = SYNC[state];
  return <div className={'syncline ' + state}><I name={ic} size={14} /><span>{text || t}</span>{state === 'error' && <a>Réessayer</a>}</div>;
}
function AppBar({ title, sub, back, logo, actions, sync = 'ok', syncText, small }) {
  return <header className="appbar"><div className={'appbar-row' + (small ? ' sm' : '')}>
    {back && <IconBtn icon="arrow-left" label="Retour" />}{logo && <LogoSlot size={40} />}
    <div className="appbar-title" style={{ marginLeft: back || logo ? 4 : 0 }}><h1>{title}</h1>{sub && <p>{sub}</p>}</div>{actions}</div>
    {sync && <SyncLine state={sync} text={syncText} />}</header>;
}
function NetBar({ pending = 0 }) {
  return <div className="netbar"><I name="wifi-off" size={16} /><span>Hors ligne{pending ? ` · ${pending} saisies en attente d’envoi` : ''}</span></div>;
}
function Group({ label, action, children, style }) {
  return <section className="grp" style={style}>{(label || action) && <div className="grp-h"><span className="caps">{label}</span>{action && <a>{action}</a>}</div>}<div className="card list">{children}</div></section>;
}
function Row({ lead, title, sub, end, chevron }) {
  return <div className="row">{lead}<div className="row-main"><div className="row-t">{title}</div>{sub && <div className="row-s">{sub}</div>}</div>{end && <div className="row-end">{end}</div>}{chevron && <I name="chevron-right" size={18} style={{ color: 'var(--text-tertiary)' }} />}</div>;
}
function Chip({ s, tone, children }) {
  if (s) return <DS.Badge tone={STATUS[s][0]}>{STATUS[s][1]}</DS.Badge>;
  return <DS.Badge tone={tone}>{children}</DS.Badge>;
}
function MAvatar({ name, status, diaspora, size = 44 }) {
  return <div className="mav" style={{ width: size, height: size }}><DS.Avatar name={name} size={size} />{status && <span className={'mav-dot s-' + status} />}{diaspora && <span className="mav-dia" title="Diaspora"><I name="globe" size={11} /></span>}</div>;
}
function Dia() { return <span className="dia"><I name="globe" size={13} />Diaspora</span>; }
function EventCard({ type, title, wd, day, mon, time, place, dress, foot }) {
  return <div className="card"><div className="ev"><div className="ev-date"><small>{wd}</small><b>{day}</b><small>{mon}</small></div>
    <div><div className="ev-type">{type}</div><div className="ev-t">{title}</div><div className="meta">
      {time && <div><I name="clock" size={16} /><span className="tnum">{time}</span></div>}
      {place && <div><I name="map-pin" size={16} />{place}</div>}
      {dress && <div><I name="shirt" size={16} />{dress}</div>}</div></div></div>
    {foot && <div style={{ borderTop: '1px solid var(--border-subtle)', padding: '12px 16px' }}>{foot}</div>}</div>;
}
function AnnCard({ cat, catTone = 'neutral', title, text, author, time, pinned, unread, reads, file, convoc }) {
  return <article className="card ann"><div className="ann-top"><Chip tone={catTone}>{cat}</Chip>{pinned && <span style={{ display: 'flex', gap: 4, alignItems: 'center', fontWeight: 700 }}><I name="pin" size={14} />Épinglé</span>}<time>{time}</time></div>
    <div className="ann-t">{unread && <span className="ud" aria-label="Non lu" />}<span>{title}</span></div>
    {text && <p className="ann-x">{text}</p>}
    {convoc && <div className="convoc"><I name="calendar-check" size={16} />{convoc}</div>}
    {file && <div className="file"><I name="file-text" size={20} /><div><b>{file}</b>PDF · 240 Ko</div></div>}
    <div className="ann-f"><span>{author}</span>{reads && <span style={{ marginLeft: 'auto', fontWeight: 700, color: 'var(--text-primary)' }}><I name="eye" size={14} />{reads}</span>}</div></article>;
}
function Field({ label, value, placeholder, hint, error, icon, trailing, req, multi, focus, locked }) {
  return <div className={'fld' + (error ? ' is-err' : '') + (focus ? ' is-focus' : '')}><span className="fld-l">{label}{req && <em> *</em>}</span>
    <span className={'fld-box' + (multi ? ' multi' : '') + (locked ? ' locked' : '')}>{icon && <I name={icon} size={18} />}<span className={value ? 'fld-v' : 'fld-ph'}>{value || placeholder}</span>{trailing}</span>
    {(error || hint) && <span className="fld-h">{error && <I name="circle-alert" size={14} />}{error || hint}</span>}</div>;
}
function AmountField({ label = 'Montant', value, quick = [500, 1000, 2000, 2500], on }) {
  return <div className="fld"><span className="fld-l">{label}<em> *</em></span><div className="amt-box"><b>{value ? fmt(value) : '0'}</b><span>FCFA</span></div>
    <div className="quick">{quick.map(q => <button key={q} className={q === on ? 'on' : ''}>{fmt(q)}</button>)}</div></div>;
}
function Seg2({ options, on = 0 }) {
  return <div className="seg2">{options.map((o, i) => <button key={i} className={i === on ? 'on' : ''}>{o}</button>)}</div>;
}
function Btn({ v = 'primary', children, full, style, size }) {
  return <DS.Button variant={v} size={size} style={{ minHeight: 48, ...(full ? { width: '100%', minHeight: 52 } : {}), ...style }}>{children}</DS.Button>;
}
function Sheet({ title, children, top }) {
  return <div className="overlay bottom">{top}<div className="sheet"><div className="handle" />{title && <h3>{title}</h3>}{children}</div></div>;
}
function Dialog({ title, children, acts }) {
  return <div className="overlay center"><div className="dialog" role="dialog"><h3>{title}</h3>{children}<div className="acts">{acts}</div></div></div>;
}
function Toast({ icon = 'circle-check', children, action, stat }) {
  return <div className={'toast' + (stat ? ' static' : '')} role="status"><I name={icon} size={18} /><span>{children}</span>{action && <a>{action}</a>}</div>;
}
function EmptyState({ icon, title, text, action, err }) {
  return <div className={'state' + (err ? ' err' : '')}><div className="ico"><I name={icon} size={28} /></div><h3>{title}</h3><p>{text}</p>{action}</div>;
}
function Restricted({ title = 'Accès réservé', text }) {
  return <div className="restricted"><div className="ico"><I name="lock" size={20} /></div><div><b>{title}</b><p>{text}</p></div></div>;
}
function Check({ on, done }) { return <span className="hit"><span className={'check' + (on ? ' on' : '') + (done ? ' done' : '')}>{(on || done) && <I name="check" size={16} />}</span></span>; }
function Thirds({ n }) { return <span className="thirds" aria-label={`${n} tranche(s) sur 3`}>{[0, 1, 2].map(i => <i key={i} className={i < n ? 'on' : ''} />)}</span>; }
function Pin({ n = 0, err }) { return <div className={'pin' + (err ? ' err' : '')}>{[0, 1, 2, 3].map(i => <i key={i} className={i < n ? 'on' : ''} />)}</div>; }
function Keypad() {
  return <div className="keypad">{['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(k => <button key={k}>{k}</button>)}<button className="ghost" aria-label="Empreinte"><I name="fingerprint" size={24} /></button><button>0</button><button className="ghost" aria-label="Effacer"><I name="delete" size={24} /></button></div>;
}
function Fab({ children = 'Ajouter', icon = 'plus' }) {
  return <div className="fab"><DS.Button variant="primary" style={{ minHeight: 56, paddingLeft: 20, paddingRight: 24, boxShadow: 'var(--shadow-dialog)' }}><I name={icon} size={20} />{children}</DS.Button></div>;
}
Object.assign(window, { DS, I, fmt, Amt, Phone, LogoSlot, IconBtn, SyncLine, AppBar, NetBar, Group, Row, Chip, MAvatar, Dia, EventCard, AnnCard, Field, AmountField, Seg2, Btn, Sheet, Dialog, Toast, EmptyState, Restricted, Check, Thirds, Pin, Keypad, Fab, ROLE_TABS, TAB_DEF, STATUS });
