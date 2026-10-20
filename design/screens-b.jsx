const BOOK = [
  [1, 'Contribution décès · Nkotto', 'Essomba Kévin', 'Saisi par Fotso I. · lun. 19 oct., 10:12', 'pending', 2500],
  [1, 'Inscription · Ndjock Patrick', '', 'Saisi par Fotso I. · dim. 18 oct., 16:40', 'local', 500],
  [-1, 'Dépense · cierges et fleurs', 'Veillée de la Toussaint', 'Saisi par Fotso I. · sam. 17 oct., 18:05 · Validé par Tchoumi A.', 'ok', 12000],
  [1, 'Amende · retard à l’assise', 'Mbella Grâce', 'Saisi par Fotso I. · sam. 17 oct., 15:30 · Validé par Tchoumi A.', 'ok', 500],
];
function BookRow({ r }) {
  const [d, t, who, meta, st, v] = r;
  return <Row lead={<DS.IconChip tint={d > 0 ? 'green' : 'purple'} size={40} icon={<I name={d > 0 ? 'arrow-down-left' : 'arrow-up-right'} />} />}
    title={t} sub={<span style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>{who && <span>{who}</span>}<span style={{ fontSize: 12 }}>{meta}</span>
      {st === 'pending' && <span><Chip tone="amber">À valider</Chip></span>}{st === 'local' && <span className="pending"><I name="cloud-off" size={13} />Pas encore envoyé</span>}</span>}
    end={<Amt v={d * v} sign tone={d > 0 ? 'msg-green-600' : 'text-primary'} />} />;
}
function SFinances() {
  return <Phone label="Finances · livre de caisse" note="Chaque ligne : qui a saisi, quand, qui a validé. Une saisie hors ligne reste marquée jusqu’à l’envoi." role="tresorier" active="finances" toast={<Fab>Opération</Fab>}>
    <AppBar title="Finances" actions={<IconBtn icon="file-down" label="Exporter en PDF" />} />
    <div className="scroll" style={{ gap: 16 }}>
      <div className="bal"><span className="caps">Solde de la caisse</span><b>186{'\u202F'}500 <span className="amt-cur" style={{ fontSize: 18 }}>FCFA</span></b><span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Validé jusqu’au mercredi 30 septembre 2026</span></div>
      <DS.SegmentedTabs options={['Livre de caisse', 'Solidarité', 'Recouvrement', 'Rapports']} active={0} onChange={() => { }} />
      <div className="card list">{BOOK.map((r, i) => <BookRow key={i} r={r} />)}</div>
    </div>
  </Phone>;
}
function SEntry() {
  return <Phone label="Nouvelle opération" note="Montant en grand, raccourcis aux montants officiels. La catégorie ouvre une feuille de choix.">
    <AppBar back title="Nouvelle opération" small sync={null} />
    <div className="scroll" style={{ gap: 16 }}>
      <Seg2 options={[<><I name="arrow-down-left" size={16} />Entrée</>, <><I name="arrow-up-right" size={16} />Sortie</>]} on={0} />
      <AmountField value={2500} on={2500} />
      <Field label="Catégorie" req value="Contributions de solidarité" trailing={<I name="chevron-down" size={18} />} />
      <Field label="Membre" req value="Essomba Kévin" icon="user-round" trailing={<I name="chevron-down" size={18} />} />
      <Field label="Date" value="lundi 19 octobre 2026" icon="calendar" />
    </div>
    <div className="footer-bar"><span style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'flex', gap: 6, alignItems: 'center' }}><I name="shield-check" size={14} />Sera validée par le commissaire aux comptes.</span><Btn full>Enregistrer</Btn></div>
  </Phone>;
}
function SEntrySheet() {
  const cats = [['Inscriptions', '500 FCFA à l’adhésion'], ['Amendes', 'Retards, absences, tenue'], ['Aides et dons', 'Dons reçus, aides versées'], ['Contributions de solidarité', 'Médaille, maladie, décès'], ['Dépenses', 'Achats, transport, matériel']];
  return <Phone label="Feuille de choix · catégorie" note="Bottom sheet : liste courte, cibles pleine largeur, fond assombri."
    overlay={<Sheet title="Catégorie">{<div className="list" style={{ padding: 0 }}>{cats.map(([c, s], i) => <Row key={c} lead={<span className={'radio' + (i === 3 ? ' on' : '')} />} title={c} sub={s} />)}</div>}</Sheet>}>
    <AppBar back title="Nouvelle opération" small sync={null} />
    <div className="scroll"><AmountField value={2500} on={2500} /></div>
  </Phone>;
}
const SOLI = [
  ['Ateba Sandrine', 3, true], ['Eboa Lionel', 3], ['Essomba Kévin', 1, false, true], ['Mbella Grâce', 0], ['Moukouri Danielle', 2], ['Ndjock Patrick', 0, false, true],
];
function SSolidarity() {
  return <Phone label="Contribution de solidarité · qui a payé" note="Recouvrement par tiers : une tranche par semaine sur un mois. Cocher puis enregistrer en une fois.">
    <AppBar back title="Décès · famille Nkotto" sub="2 500 FCFA par membre · ouvert le 12 octobre" small />
    <div className="scroll" style={{ gap: 16 }}>
      <div className="card pad" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}><span style={{ fontWeight: 800, fontSize: 16 }}>27 sur 41 ont tout payé</span><Amt v={78400} /></div>
        <span className="progress"><i style={{ width: '66%' }} /></span>
        <span style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.45 }}>Tranches de 834 · 833 · 833 FCFA, à verser les samedis 17, 24 et 31 octobre.</span>
      </div>
      <DS.SegmentedTabs options={['À payer 14', 'Payé 27', 'Tous 41']} active={2} onChange={() => { }} />
      <div className="card list">{SOLI.map(([n, t, d, sel]) => <Row key={n} lead={<Check on={sel} done={t === 3} />} title={<span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>{n}{d && <I name="globe" size={13} style={{ color: 'var(--text-secondary)' }} />}</span>} sub={<span style={{ display: 'flex', gap: 8, alignItems: 'center' }}><Thirds n={t} />{t === 3 ? 'Payé' : `${t}/3 tranches`}</span>} end={<Amt v={Math.round(2500 * t / 3)} weight={600} />} />)}</div>
    </div>
    <div className="footer-bar"><Btn full>Enregistrer 2 paiements · 1 667 FCFA</Btn></div>
  </Phone>;
}
function SReport() {
  const lines = [['Inscriptions', 4500], ['Amendes', 9000], ['Aides et dons', 35000], ['Contributions de solidarité', 70000]];
  return <Phone label="Rapport trimestriel · commissaire aux comptes" note="Lecture + validation. Les opérations non vérifiées bloquent la validation du rapport." role="cac" active="finances">
    <AppBar back title="Rapport T3 2026" sub="juillet – septembre" small actions={<IconBtn icon="file-down" label="Exporter en PDF" />} />
    <div className="scroll" style={{ gap: 16 }}>
      <Group label="Synthèse">
        <Row title="Solde d’ouverture" sub="mercredi 1er juillet 2026" end={<Amt v={142000} />} />
        <Row title="Entrées" end={<Amt v={118500} sign tone="msg-green-600" />} />
        <Row title="Sorties" end={<Amt v={-74000} sign />} />
        <Row title="Solde de clôture" sub="mercredi 30 septembre 2026" end={<Amt v={186500} weight={800} size={17} />} />
      </Group>
      <Group label="Entrées par catégorie">{lines.map(([c, v]) => <Row key={c} title={c} end={<Amt v={v} weight={600} />} />)}</Group>
    </div>
    <div className="footer-bar"><div className="notice warn"><I name="triangle-alert" size={18} /><span>3 opérations restent à vérifier avant de valider.</span></div><Btn full v="outline">Vérifier les 3 opérations</Btn></div>
  </Phone>;
}
function SCalendar() {
  const ev = { 3: ['g'], 4: ['n'], 10: ['g'], 11: ['n'], 17: ['g'], 18: ['n', 'g'], 24: ['g'], 25: ['n'], 31: ['g', 'n'] };
  const cells = []; for (let i = 0; i < 3; i++) cells.push(<div key={'p' + i} className="d mut">{28 + i}</div>);
  for (let d = 1; d <= 31; d++) cells.push(<div key={d} className={'d' + (d === 19 ? ' today' : '') + (d === 24 ? ' sel' : '')}>{d}<span className="dots">{(ev[d] || []).map((t, j) => <i key={j} className={t} />)}</span></div>);
  cells.push(<div key="n1" className="d mut">1</div>);
  return <Phone label="Calendrier · mois" note="Point vert : assise / réunion. Point foncé : messe ou service. Aujourd’hui cerclé, jour choisi plein." role="tresorier" active="calendrier">
    <AppBar title="Calendrier" actions={<IconBtn icon="plus" label="Nouvel événement" />} />
    <div className="scroll" style={{ gap: 12 }}>
      <Seg2 options={['Mois', 'Agenda', 'Planning']} on={0} />
      <div style={{ display: 'flex', alignItems: 'center' }}><IconBtn icon="chevron-left" label="Mois précédent" /><b style={{ flex: 1, textAlign: 'center', fontSize: 17 }}>octobre 2026</b><IconBtn icon="chevron-right" label="Mois suivant" /></div>
      <div className="cal">{['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((w, i) => <div key={i} className="wd">{w}</div>)}{cells}</div>
      <div className="card list">
        <Row lead={<b className="tnum" style={{ width: 48, fontSize: 15 }}>15:00</b>} title="Assise du samedi" sub="Salle paroissiale · tenue intérieure" chevron />
      </div>
    </div>
  </Phone>;
}
function SEvent() {
  return <Phone label="Détail d’un événement" note="Vue membre : sa présence, la tenue, les rappels. Nuit : horaire explicite de fin." role="membre" active="calendrier">
    <AppBar back title="" small />
    <div className="scroll" style={{ gap: 20, paddingTop: 0 }}>
      <div><div className="ev-type">Grande veillée</div><div style={{ fontSize: 24, fontWeight: 800, marginTop: 4, lineHeight: 1.25 }}>Veillée de la Toussaint</div></div>
      <div className="card list">
        <Row lead={<I name="calendar" />} title="samedi 31 octobre 2026" sub={<span className="tnum">22:00 → dimanche 05:00 · nuit</span>} />
        <Row lead={<I name="map-pin" />} title="Église Notre-Dame de Lourdes" sub="Yapoma, Douala" />
        <Row lead={<I name="shirt" />} title="Tenue intérieure" sub="Aube blanche, cordon, chaussures noires" />
      </div>
      <section className="grp"><div className="grp-h"><span className="caps">Ma présence</span></div><div className="card pad" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}><div><div className="row-t">Pas encore marquée</div><div className="row-s">Le censeur fait l’appel sur place</div></div><Btn v="secondary" full>Prévenir d’une absence</Btn></div></section>
      <Group label="Rappels">
        <Row title="La veille à 20:00" end={<DS.Toggle checked onChange={() => { }} />} />
        <Row title="2 heures avant" end={<DS.Toggle checked={false} onChange={() => { }} />} />
      </Group>
    </div>
  </Phone>;
}
function SAttendance() {
  const rows = [['Ateba Sandrine', 'e', true], ['Eboa Lionel', 'p'], ['Essomba Kévin', 'p'], ['Fotso Ingrid', 'a'], ['Mbella Grâce', ''], ['Ndjock Patrick', '']];
  return <Phone label="Appel · présences (censeur)" note="Trois choix par ligne, 44 dp, lettre + couleur. Fonctionne hors ligne." role="censeur" active="calendrier" net="offline">
    <NetBar pending={4} />
    <AppBar back title="Appel · assise du 24 oct." small sync="offline" />
    <div className="scroll" style={{ gap: 12 }}>
      <div className="msg-stat"><DS.StatRow stats={[{ value: '18', label: 'Présents' }, { value: '2', label: 'Absents' }, { value: '3', label: 'Excusés' }, { value: '18', label: 'Restants' }]} /></div>
      <div className="card list">{rows.map(([n, s, d]) => <Row key={n} lead={<MAvatar name={n} size={36} diaspora={d} />} title={n} sub={d ? 'À distance' : null} end={<div className="att">{[['p', 'P', 'Présent'], ['a', 'A', 'Absent'], ['e', 'E', 'Excusé']].map(([k, l, t]) => <button key={k} aria-label={t} className={s === k ? k : ''}>{l}</button>)}</div>} />)}</div>
    </div>
  </Phone>;
}
function SFeed() {
  return <Phone label="Annonces · fil" note="Épinglé en tête. Point vert = non lu. L’expéditeur voit le nombre de lectures." role="sg" active="annonces" toast={<Fab icon="pencil">Rédiger</Fab>}>
    <AppBar title="Annonces" actions={<IconBtn icon="search" label="Rechercher" />} />
    <div className="scroll" style={{ gap: 12 }}>
      <DS.SegmentedTabs options={['Toutes', 'Convocations', 'Non lues 2', 'Envoyées']} active={0} onChange={() => { }} />
      <AnnCard cat="Convocation" catTone="green" pinned unread title="Assemblée générale ordinaire" text="Présence obligatoire pour tous les gardes. Ordre du jour : bilan du trimestre, préparation de la Toussaint." convoc="samedi 7 novembre 2026 · 15:00" file="Convocation_AG_nov2026.pdf" author="Ngo Nyemb C. · Secrétaire générale" reads="Lu par 32 sur 48" time="lun. 10:05" />
      <AnnCard cat="Vie du mouvement" unread title="Répétition des chants pour la veillée" text="Rendez-vous jeudi à 18:00 à l’église." author="Din Yannick · Formateur" time="hier" />
    </div>
  </Phone>;
}
function SComposer() {
  return <Phone label="Rédiger une annonce" note="Une convocation se lie à un événement du calendrier et notifie tous les destinataires.">
    <AppBar back title="Nouvelle annonce" small sync={null} actions={<a style={{ padding: '0 8px' }}>Brouillon</a>} />
    <div className="scroll" style={{ gap: 16 }}>
      <Seg2 options={['Annonce', 'Convocation']} on={1} />
      <Field label="Titre" req value="Assemblée générale ordinaire" />
      <Field label="Message" multi value="Présence obligatoire pour tous les gardes. Ordre du jour : bilan du trimestre, préparation de la Toussaint." />
      <div className="card list">
        <Row lead={<DS.IconChip tint="green" size={40} icon={<I name="calendar-check" />} />} title="Assemblée générale" sub="samedi 7 novembre 2026 · 15:00" chevron />
        <Row lead={<DS.IconChip tint="red" size={40} icon={<I name="paperclip" />} />} title="Convocation_AG_nov2026.pdf" sub="240 Ko" end={<IconBtn icon="x" label="Retirer" />} />
        <Row lead={<DS.IconChip tint="purple" size={40} icon={<I name="users" />} />} title="Tous les membres" sub="48 destinataires" chevron />
        <Row title="Épingler en tête du fil" end={<DS.Toggle checked onChange={() => { }} />} />
      </div>
    </div>
    <div className="footer-bar"><Btn full><I name="send" size={18} />Envoyer la convocation</Btn></div>
  </Phone>;
}
function SReads() {
  return <Phone label="Accusés de lecture (expéditeur)" note="Lu / non lu par membre, avec relance groupée."
    overlay={<Sheet title="Lu par 32 sur 48"><Seg2 options={['Non lu 16', 'Lu 32']} on={0} />
      <div className="list" style={{ padding: 0 }}>{['Mbella Grâce', 'Ndjock Patrick', 'Moukouri Danielle'].map(n => <Row key={n} lead={<MAvatar name={n} size={36} />} title={n} sub="Non lu" />)}</div>
      <Btn full v="secondary"><I name="bell-ring" size={18} />Relancer les 16 non-lecteurs</Btn></Sheet>}>
    <AppBar title="Annonces" />
  </Phone>;
}
function SNotifs() {
  const today = [['megaphone', 'green', 'Nouvelle convocation', 'Assemblée générale · samedi 7 novembre, 15:00', '10:05', true], ['bell', 'amber', 'Rappel : assise samedi 15:00', 'Tenue intérieure · salle paroissiale', '08:00', true]];
  const week = [['circle-check', 'green', 'Paiement validé', 'Médaille · Mbella Grâce · 2 000 FCFA', 'sam.'], ['user-plus', 'purple', 'Nouveau membre', 'Ndjock Patrick a rejoint le mouvement', 'ven.']];
  const R = ([ic, t, ti, s, h, u]) => <Row key={ti} lead={<DS.IconChip tint={t} size={40} icon={<I name={ic} />} />} title={<span style={{ display: 'flex', gap: 6, alignItems: 'center' }}>{u && <span className="ud" style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--msg-green-500)' }} />}{ti}</span>} sub={s} end={<span style={{ fontSize: 12, color: 'var(--text-secondary)' }}>{h}</span>} />;
  return <Phone label="Notifications" note="Regroupées par jour ; le point vert disparaît à l’ouverture.">
    <AppBar back title="Notifications" small actions={<a style={{ padding: '0 8px', fontSize: 14 }}>Tout lire</a>} />
    <div className="scroll" style={{ gap: 20 }}>
      <Group label="Aujourd’hui">{today.map(R)}</Group>
      <Group label="Cette semaine">{week.map(R)}</Group>
    </div>
  </Phone>;
}
Object.assign(window, { BOOK, BookRow, SFinances, SEntry, SEntrySheet, SSolidarity, SReport, SCalendar, SEvent, SAttendance, SFeed, SComposer, SReads, SNotifs });
