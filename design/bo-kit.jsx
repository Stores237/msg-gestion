const BO_NAV = [['dash', 'layout-dashboard', 'Tableau de bord'], ['users', 'users', 'Utilisateurs'], ['roles', 'shield', 'Rôles et permissions'], ['assign', 'calendar-range', 'Affectations', '2'], ['audit', 'scroll-text', 'Journal d’audit'], ['settings', 'settings', 'Paramètres']];
function BoFrame({ label, note, url = 'admin.msg-yapoma.cm', children, modal }) {
  return <figure className="bo-fig" data-screen-label={label}><div className="bo"><div className="bo-chrome"><i /><i /><i /><span><I name="lock" size={12} />{url}</span></div>{children}{modal && <div className="bo-modal">{modal}</div>}</div>
    <figcaption><b>{label}</b>{note && <span>{note}</span>}</figcaption></figure>;
}
function Shell({ active, title, crumb, acts, children }) {
  return <div className="bo-shell"><aside className="bo-side"><div className="bo-brand"><LogoSlot size={36} /><div><b>MSG Gestion</b><small>Back-office</small></div></div>
    {BO_NAV.map(([k, ic, l, n]) => <div key={k} className={'bo-nav' + (k === active ? ' on' : '')}><I name={ic} size={18} />{l}{n && <em>{n}</em>}</div>)}
    <div className="sp" /><div className="bo-me"><DS.Avatar name="Tchakounté Alain" size={36} /><div><b>Tchakounté A.</b><RoleBadge t="sys">Super admin</RoleBadge></div></div></aside>
    <main className="bo-main"><div className="bo-top"><div>{crumb && <div className="crumb">{crumb}</div>}<h1>{title}</h1></div><div className="acts">{acts}</div></div><div className="bo-body">{children}</div></main></div>;
}
function RoleBadge({ t, children, until }) {
  return <span className={'rb' + (t ? ' ' + t : '')}><i />{children}{until && <span style={{ fontWeight: 600, opacity: .85 }}>· {until}</span>}{t === 'temp' && <I name="timer" size={12} />}</span>;
}
function St({ s, children }) { return <span className={'status ' + s}><i />{children}</span>; }
function Cbx({ on }) { return <span className={'cbx' + (on ? ' on' : '')}>{on && <I name="check" size={14} />}</span>; }
function Panel({ title, acts, children, pad, style }) {
  return <section className="panel" style={style}>{title && <div className="panel-h"><h2>{title}</h2>{acts && <div className="acts">{acts}</div>}</div>}{pad ? <div className="panel-b">{children}</div> : children}</section>;
}
function FSel({ children, on }) { return <span className={'fsel' + (on ? ' on' : '')}>{children}<I name="chevron-down" size={14} /></span>; }
function Masked() { return <span style={{ display: 'inline-flex', gap: 6, alignItems: 'center', color: 'var(--text-secondary)', fontWeight: 600 }}><I name="eye-off" size={14} />Montant masqué</span>; }
const PM_ACTIONS = ['Voir', 'Créer', 'Modifier', 'Valider', 'Supprimer', 'Exporter'];
// value codes: 1 on, 0 off, 'n' n/a, 'l' locked (séparation des tâches), 'c' changed (on), 'x' changed (off)
function PermMatrix({ rows }) {
  const cell = v => v === 'n' ? <span className="pc na">—</span> : v === 'l' ? <span className="pc lock" title="Bloqué : séparation des tâches"><I name="lock" size={14} /></span> : <span className={'pc' + (v === 1 || v === 'c' ? ' on' : '') + (v === 'c' || v === 'x' ? ' chg' : '')}>{(v === 1 || v === 'c') && <I name="check" size={16} />}</span>;
  return <div className="tbl-wrap"><table className="pm"><thead><tr><th>Module · objet</th>{PM_ACTIONS.map(a => <th key={a}>{a}</th>)}</tr></thead><tbody>
    {rows.map((r, i) => r.mod ? <tr key={i} className="mod"><td colSpan={7}>{r.mod}</td></tr> : <tr key={i}><td><b>{r.n}</b>{r.s && <small>{r.s}</small>}</td>{r.v.map((v, j) => <td key={j}>{cell(v)}</td>)}</tr>)}</tbody></table>
    <div className="legend"><span><span className="pc on" style={{ display: 'inline-flex' }} />Autorisé</span><span><span className="pc" style={{ display: 'inline-flex', boxShadow: 'inset 0 0 0 1.5px var(--border-subtle)' }} />Non autorisé</span><span><span className="pc lock" style={{ display: 'inline-flex', background: 'var(--surface-sunken)' }} />Bloqué (séparation des tâches)</span><span><span className="pc chg" style={{ display: 'inline-flex', outline: '2px solid var(--amber-500)' }} />Modifié, non enregistré</span></div></div>;
}
function MiniPhone({ role, children }) {
  const keys = ROLE_TABS[role];
  return <div className="mini-phone"><div style={{ padding: '16px 14px 8px' }}><div style={{ fontSize: 16, fontWeight: 800 }}>Accueil</div></div><div style={{ padding: '0 14px 14px', display: 'flex', flexDirection: 'column', gap: 8, minHeight: 200 }}>{children}</div>
    <div className="msg-tabbar"><DS.BottomNav items={keys.map(k => ({ icon: <I name={TAB_DEF[k][0]} size={18} />, label: TAB_DEF[k][1] }))} active={0} onChange={() => { }} /></div></div>;
}
Object.assign(window, { BoFrame, Shell, RoleBadge, St, Cbx, Panel, FSel, Masked, PermMatrix, MiniPhone, PM_ACTIONS });
