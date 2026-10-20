const POSTS = ['Première centrale', 'Deuxième centrale', 'Contrôle', 'Petites portes', 'Mésanie'];
const SIZE_POSTS = { 2: 1, 4: 2, 6: 3, 8: 4, 10: 5, 12: 5 };
const MESSES = [
  { wd: 'sam. 24', t: '18:30', name: 'Messe anticipée', size: 6, chef: 'Eboa L.', grp: 'Saint-Michel', cells: [['Eboa L.', 'conf'], ['Fotso I.', 'conf'], ['Kotto H.', 'conf'], ['Bilong S.', 'pend'], ['Manga Y.', 'conf'], ['Etoundi C.', 'conf']] },
  { wd: 'dim. 25', t: '06:30', name: 'Première messe', size: 4, chef: 'Din Y.', grp: 'Saint-Tarcisius', cells: [['Essomba K.', 'conflict'], ['Din Y.', 'conf'], ['Nkoulou P.', 'pend'], ['Ndjock P.', 'conf']] },
  { wd: 'dim. 25', t: '09:00', name: 'Grand-messe', size: 10, chef: 'Kotto H.', grp: 'Sainte-Agnès', warn: true, cells: [['Ngo Mbock R.', 'conf'], ['Ateba S.', 'conf'], ['Tchoumi A.', 'conf'], ['', 'empty'], ['Eboa L.', 'pend'], ['Ewane B.', 'conf'], ['', 'empty'], ['Moukouri D.', 'conf'], ['Fotso I.', 'pend'], ['Manga Y.', 'conf']] },
];
function DutyChip({ s }) {
  const m = { pend: ['amber', 'À confirmer'], conf: ['green', 'Confirmé'], swap: ['neutral', 'Échange demandé'], repl: ['neutral', 'Remplacé'] };
  if (s === 'conflict') return <span className="chip-x">Conflit</span>;
  return <DS.Badge tone={m[s][0]}>{m[s][1]}</DS.Badge>;
}
function PCell({ n, st = 'conf', side, big }) {
  if (st === 'empty') return <div className="pcell empty">{side && <em>{side}</em>}<span>+ Libre</span></div>;
  return <div className={'pcell ' + st}>{side && <em>{side}</em>}<span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', paddingRight: 10 }}>{n}</span>
    <span className="st">{st === 'conf' && <I name="check" size={12} />}{st === 'pend' && <i />}{st === 'conflict' && <I name="triangle-alert" size={12} />}</span></div>;
}
function PCol({ m }) {
  const np = SIZE_POSTS[m.size];
  return <div className={'pcol' + (m.warn ? ' warn' : '')}>
    <div className="pcol-h"><b>{m.wd} · {m.t}</b><span>{m.name} · {m.cells.filter(c => c[1] !== 'empty').length}/{m.size}</span></div>
    <div className="pcol-chef"><I name="flag" size={12} />Chef : <b>{m.chef}</b></div>
    {POSTS.slice(0, np).map((p, i) => <div key={p} className="ppost"><small>{p}</small><div className="ppair"><PCell n={m.cells[i * 2][0]} st={m.cells[i * 2][1]} /><PCell n={m.cells[i * 2 + 1][0]} st={m.cells[i * 2 + 1][1]} /></div></div>)}
  </div>;
}
function SPlanningWeek() {
  return <Phone label="Planning · semaine" note="Une colonne par messe ; défilement horizontal. Gauche = Pariso, droite = Yapoma. Colonne cerclée = sous-effectif." role="censeur" active="calendrier">
    <AppBar title="Calendrier" actions={<IconBtn icon="users" label="Groupes" />} />
    <div className="scroll" style={{ gap: 12 }}>
      <Seg2 options={['Mois', 'Agenda', 'Planning']} on={2} />
      <div style={{ display: 'flex', alignItems: 'center' }}><IconBtn icon="chevron-left" label="Semaine précédente" /><b style={{ flex: 1, textAlign: 'center', fontSize: 15 }}>Semaine du 19 au 25 octobre</b><IconBtn icon="chevron-right" label="Semaine suivante" /></div>
      <div className="notice warn"><I name="triangle-alert" size={18} /><span><b>3 alertes</b> · Grand-messe : 8 sur 10 · Essomba K. a deux services le dimanche 25.</span></div>
      <div className="pgrid">{MESSES.map(m => <PCol key={m.t} m={m} />)}</div>
      <div className="card list"><Row lead={<DS.IconChip tint="green" size={40} icon={<I name="shirt" />} />} title="Aubes · Groupe Saint-Michel" sub="À laver avant le samedi 24, 17:00" end={<Chip tone="amber">À laver</Chip>} /></div>
    </div>
    <div className="footer-bar" style={{ flexDirection: 'row' }}><Btn v="secondary" style={{ flex: 1 }}>Brouillon</Btn><Btn style={{ flex: 2 }}><I name="send" size={18} />Publier et notifier</Btn></div>
  </Phone>;
}
function SAssign() {
  const cand = [['Bilong Steve', '1 service ce mois', null], ['Nkoulou Paule', '2 services ce mois', null], ['Essomba Kévin', 'Déjà à 06:30 ce dimanche', 'warn'], ['Mbella Grâce', 'En congé jusqu’au 15 novembre', 'off']];
  return <Phone label="Affecter un poste" note="Toucher une case libre ouvre les gardes disponibles, triés par nombre de services. On peut aussi glisser un nom d’une case à l’autre."
    overlay={<Sheet title="Petites portes · Yapoma"><span style={{ fontSize: 13, color: 'var(--text-secondary)', padding: '0 4px' }}>Les moins sollicités en premier</span>
      <div className="list" style={{ padding: 0 }}>{cand.map(([n, s, f]) => <div key={n} style={{ opacity: f === 'off' ? .55 : 1 }}><Row lead={<MAvatar name={n} size={36} status={f === 'off' ? 'conge' : 'actif'} />} title={n} sub={<span style={{ display: 'flex', gap: 4, alignItems: 'center', color: f === 'warn' ? 'var(--amber-600)' : undefined, fontWeight: f ? 600 : 400 }}>{f === 'warn' && <I name="triangle-alert" size={13} />}{f === 'off' && <I name="lock" size={13} />}{s}</span>} end={f === 'off' ? null : <Btn v={f ? 'outline' : 'secondary'} size="sm">{f ? 'Quand même' : 'Affecter'}</Btn>} /></div>)}</div></Sheet>}>
    <AppBar back title="Grand-messe · 09:00" sub="dimanche 25 octobre · Groupe Sainte-Agnès" small sync={null} />
    <div className="scroll" style={{ gap: 14 }}>
      <div className="fld"><span className="fld-l">Nombre de gardes</span><div className="sizes">{[2, 4, 6, 8, 10, 12].map(s => <button key={s} className={s === 10 ? 'on' : ''}>{s}</button>)}</div></div>
      <Btn v="secondary" full><I name="users" size={18} />Affecter un groupe</Btn>
      {[['Petites portes', ['Moukouri D.', 'conf'], ['Choisir…', 'sel']], ['Mésanie', ['Fotso I.', 'pend'], ['Manga Y.', 'conf']]].map(([p, a, b]) => <div key={p} className="ppost"><span className="slot-l">{p}</span><div className="slots"><PCell side="Pariso" n={a[0]} st={a[1]} /><PCell side="Yapoma" n={b[0]} st={b[1]} /></div></div>)}
    </div>
  </Phone>;
}
function SAssignGroup() {
  const g = [['Saint-Michel', 'Eboa Lionel', '7 gardes · 7 disponibles', true], ['Sainte-Agnès', 'Kotto Hervé', '9 gardes · 8 disponibles'], ['Saint-Tarcisius', 'Din Yannick', '6 gardes · 4 disponibles · 2 en congé']];
  return <Phone label="Affecter un groupe entier" note="Une action : le groupe et son chef remplissent les postes ; les indisponibles sont exclus et les cases restantes signalées."
    overlay={<Sheet title="Affecter un groupe"><div className="list" style={{ padding: 0 }}>{g.map(([n, c, s, on]) => <Row key={n} lead={<span className={'radio' + (on ? ' on' : '')} />} title={'Groupe ' + n} sub={<>Chef : {c}<br />{s}</>} />)}</div>
      <div className="notice"><I name="info" size={18} /><span>Messe anticipée · 6 postes. Le chef de groupe sera notifié en premier.</span></div><Btn full>Affecter Saint-Michel</Btn></Sheet>}>
    <AppBar back title="Messe anticipée · 18:30" sub="samedi 24 octobre" small sync={null} />
  </Phone>;
}
function SMesServices() {
  return <Phone label="Mes services · notification" note="Le membre ne voit que ses propres services. Un tap pour confirmer ou demander un échange." role="membre" active="calendrier"
    overlay={<div className="push"><div className="app">MSG</div><div style={{ flex: 1 }}><div style={{ display: 'flex' }}><b>Nouveau service</b><small>maintenant</small></div><p>Dimanche 25 octobre, 06:30 · première centrale (Pariso). Confirmez votre présence.</p></div></div>}>
    <AppBar title="Calendrier" />
    <div className="scroll" style={{ gap: 12 }}>
      <Seg2 options={['Mois', 'Agenda', 'Mes services']} on={2} />
      <div className="card duty"><div className="duty-top"><span className="ev-type">dim. 25 oct. · 06:30</span><DutyChip s="pend" /></div><div className="duty-t">Première centrale · Pariso</div><div className="meta"><div><I name="flag" size={16} />Chef : Din Yannick</div><div><I name="shirt" size={16} />Tenue intérieure</div></div>
        <div className="acts"><Btn style={{ flex: 1 }}>Confirmer</Btn><Btn v="secondary" style={{ flex: 1 }}>Échanger</Btn></div></div>
      <div className="card duty"><div className="duty-top"><span className="ev-type">dim. 1er nov. · 09:00</span><DutyChip s="conf" /></div><div className="duty-t">Contrôle · Yapoma</div></div>
    </div>
  </Phone>;
}
function SSwap() {
  return <Phone label="Demande d’échange" note="Le collègue choisi accepte, puis le chef de groupe ou le censeur valide."
    overlay={<Sheet title="Échanger mon service"><div className="card list" style={{ background: 'var(--surface-sunken)', boxShadow: 'none' }}><Row title="dim. 25 oct. · 06:30" sub="Première centrale · Pariso" /></div>
      <Field label="Avec qui ?" value="Bilong Steve" icon="user-round" trailing={<I name="chevron-down" size={18} />} hint="Disponible · 1 service ce mois" />
      <Field label="Raison (facultatif)" value="Examen le lundi, je dois réviser." />
      <span style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'flex', gap: 6, alignItems: 'center' }}><I name="shield-check" size={14} />Validation : Din Yannick, chef de groupe</span>
      <Btn full>Envoyer la demande</Btn></Sheet>}>
    <AppBar title="Calendrier" />
  </Phone>;
}
function SRequests() {
  const repl = [['Bilong Steve', '1 service ce mois · disponible'], ['Nkoulou Paule', '2 services ce mois · disponible'], ['Manga Yves', '3 services ce mois · déjà à 09:00']];
  return <Phone label="Demandes · échange et remplacement" note="Vue chef de groupe / censeur. Les remplaçants sont proposés par équité (moins de services d’abord)." role="censeur" active="calendrier">
    <AppBar back title="Demandes" sub="2 en attente" small />
    <div className="scroll" style={{ gap: 16 }}>
      <section className="grp"><div className="grp-h"><span className="caps">Échange</span></div><div className="card duty">
        <div className="duty-t" style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>Essomba K. <I name="arrow-left-right" size={16} /> Bilong S.</div>
        <div className="row-s">dim. 25 oct. · 06:30 · première centrale · accepté par Bilong S.</div>
        <div className="acts"><Btn style={{ flex: 1 }}>Approuver</Btn><Btn v="secondary" style={{ flex: 1 }}>Refuser</Btn></div></div></section>
      <section className="grp"><div className="grp-h"><span className="caps">Absence déclarée</span></div><div className="card">
        <div className="duty"><div className="duty-t">Eboa L. · sam. 24 oct. · 18:30</div><div className="row-s">Contrôle · Pariso · motif : malade</div></div>
        <div className="list" style={{ borderTop: '1px solid var(--border-subtle)' }}>{repl.map(([n, s], i) => <Row key={n} lead={<MAvatar name={n} size={36} />} title={n} sub={s} end={<Btn v={i === 0 ? 'primary' : 'secondary'} size="sm">Affecter</Btn>} />)}</div></div></section>
    </div>
  </Phone>;
}
function SAubes() {
  const fair = [['Saint-Michel', 4], ['Sainte-Agnès', 4], ['Saint-Tarcisius', 3], ['Ateba S. (diaspora)', 0], ['Kotto H.', 2]];
  return <Phone label="Lavage des aubes · rotation" note="Statut en 3 étapes, rappel automatique, compteur d’équité sur 12 mois pour faire tourner la charge." role="censeur" active="calendrier" tall>
    <AppBar back title="Lavage des aubes" small />
    <div className="scroll" style={{ gap: 16 }}>
      <div className="card pad" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <span className="caps">Semaine du 19 octobre</span><div className="duty-t">Groupe Saint-Michel</div><div className="row-s" style={{ marginTop: -8 }}>Responsable : Eboa Lionel · 12 aubes</div>
        <div className="steps3"><div className="on"><i />À laver</div><div><i />Lavées</div><div><i />Rendues</div></div>
        <Btn v="secondary" full>Marquer « lavées »</Btn></div>
      <Group label="Rappel"><Row title="Jeudi à 18:00" sub="Envoyé au responsable de la semaine" end={<DS.Toggle checked onChange={() => { }} />} /></Group>
      <Group label="Prochaines semaines" action="Modifier">
        <Row title="Semaine du 26 octobre" sub="Kotto Hervé (Sainte-Agnès)" end={<Chip tone="neutral">Prévu</Chip>} />
        <Row title="Semaine du 2 novembre" sub="Groupe Saint-Tarcisius" end={<Chip tone="neutral">Prévu</Chip>} />
      </Group>
      <section className="grp"><div className="grp-h"><span className="caps">Équité · lavages sur 12 mois</span></div><div className="card pad" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {fair.map(([n, v]) => <div key={n} className="fair"><span>{n}</span><span><i className={v < 2 ? 'lo' : ''} style={{ width: Math.max(v, .3) / 4 * 100 + '%' }} /></span><b>{v}</b></div>)}
        <span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Les membres de la diaspora sont exclus de la rotation.</span></div></section>
    </div>
  </Phone>;
}
function PlanningSpecs() {
  return <div className="doc-grid">
    <Spec title="Cellule de planning" note={<>Une case = un poste × un côté. <b>Coche</b> : confirmé. <b>Point ocre</b> : à confirmer. <b>Rouge</b> : conflit (double service, congé). <b>Pointillés</b> : libre. Maintenir pour glisser ; la case cible s’éclaire. 48 dp minimum.</>}>
      <div className="ppair"><PCell n="Fotso I." st="conf" side="Pariso" /><PCell n="Bilong S." st="pend" side="Yapoma" /></div>
      <div className="ppair"><PCell n="Essomba K." st="conflict" side="Pariso" /><PCell st="empty" side="Yapoma" /></div>
      <div className="ppair"><PCell n="Kotto H." st="drag" /><div className="pcell drop"><span>Déposer ici</span></div></div></Spec>
    <Spec title="Puce de service" note={<>Statut d’une affectation (Assignment.status). Toujours avec texte. La puce rouge « Conflit » est la seule exception à la règle « rouge = erreur », car c’en est une.</>}>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}><DutyChip s="pend" /><DutyChip s="conf" /><DutyChip s="swap" /><DutyChip s="repl" /><DutyChip s="conflict" /></div></Spec>
    <Spec title="Taille du service → postes" note={<>Chaque poste a deux côtés (Pariso, Yapoma). À 12, la mésanie passe à deux gardes par côté.</>}>
      <table className="tok-table"><tbody>{[[2, 'Première centrale'], [4, '+ Deuxième centrale'], [6, '+ Contrôle'], [8, '+ Petites portes'], [10, '+ Mésanie'], [12, 'Mésanie × 2']].map(([s, p]) => <tr key={s}><td style={{ width: 40 }}><b className="tnum">{s}</b></td><td>{p}</td></tr>)}</tbody></table></Spec>
    <Spec title="Règles et alertes" note={<>Bloquant : membre en congé ou indisponible (non proposé). Avertissement, contournable avec confirmation : double service le même jour, sous-effectif à la publication, plus de 4 services dans le mois.</>}>
      <div className="notice warn"><I name="triangle-alert" size={18} /><span>Essomba K. a déjà un service à 06:30.</span></div><div className="notice alert"><I name="circle-x" size={18} /><span>Mbella G. est en congé jusqu’au 15 novembre.</span></div></Spec>
  </div>;
}
Object.assign(window, { SPlanningWeek, SAssign, SAssignGroup, SMesServices, SSwap, SRequests, SAubes, PlanningSpecs, DutyChip, PCell });
