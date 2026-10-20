const USERS = [
  ['Ewane Brice', '+237 6 77 10 22 41', 'ok', 'Actif', [['bureau', 'Président', 'fin 30/09/2027']], 'Saint-Michel', 'aujourd’hui 09:12'],
  ['Ngo Nyemb Christelle', '+237 6 99 45 10 07', 'ok', 'Actif', [['bureau', 'Secrétaire générale'], ['sys', 'Super admin']], 'Sainte-Agnès', 'aujourd’hui 10:05'],
  ['Fotso Ingrid', '+237 6 77 45 21 08', 'ok', 'Actif', [['bureau', 'Trésorière']], 'Saint-Michel', 'hier 18:05'],
  ['Tchoumi Arnaud', '+237 6 55 31 90 12', 'ok', 'Actif', [['bureau', 'Commissaire aux comptes']], 'Saint-Tarcisius', 'lun. 12 oct.'],
  ['Eboa Lionel', '+237 6 91 02 33 58', 'ok', 'Actif', [['bureau', 'Censeur général', 'fin 30/09/2027'], ['', 'Chef de groupe']], 'Saint-Michel', 'aujourd’hui 07:40'],
  ['Kotto Hervé', '+237 6 70 88 14 63', 'ok', 'Actif', [['temp', 'Censeur du jour', 'jusqu’au 25/10']], 'Sainte-Agnès', 'hier 21:30'],
  ['Mbella Grâce', '+237 6 94 27 51 30', 'warn', 'En congé', [['', 'Membre']], 'Saint-Tarcisius', '2 oct.'],
  ['Ateba Sandrine', '+33 6 12 45 78 90', 'ok', 'Actif · diaspora', [['', 'Membre']], '—', 'sam. 17 oct.'],
  ['Moukouri Danielle', '+237 6 77 63 02 19', 'off', 'Suspendu', [['', 'Membre']], 'Sainte-Agnès', '14 août'],
];
function BLogin() {
  return <BoFrame label="Connexion · double authentification" note="Étape 2 sur 2 après numéro + mot de passe. Code SMS à 6 chiffres ; codes de secours en repli.">
    <div className="bo-center"><div className="l"><LogoSlot size={64} /><div><div style={{ fontSize: 28, fontWeight: 800, lineHeight: 1.2 }}>Back-office<br />MSG Gestion</div><p style={{ color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.55, maxWidth: 360 }}>Gestion des accès du Mouvement Garde Suisse, Paroisse Notre-Dame de Lourdes de Yapoma.</p></div><span className="caps">Service · Ordre · Accueil</span></div>
      <div className="r"><div className="bo-card"><span className="caps">Étape 2 sur 2</span><div style={{ fontSize: 24, fontWeight: 800 }}>Code de vérification</div><p style={{ margin: 0, color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.5 }}>Envoyé par SMS au +237 6•• •• •• 41. Valable 5 minutes.</p>
        <div className="otp">{['4', '8', '1', '', '', ''].map((d, i) => <span key={i} className={i === 3 ? 'f' : ''}>{d}</span>)}</div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 14, fontWeight: 600 }}>Faire confiance à cet ordinateur 30 jours<DS.Toggle checked={false} onChange={() => { }} /></div>
        <Btn full>Vérifier</Btn><div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14 }}><a>Renvoyer le code (0:42)</a><a>Utiliser un code de secours</a></div></div></div></div>
  </BoFrame>;
}
function BSessions() {
  const s = [['laptop', 'Chrome · Windows', 'Douala, Cameroun', '154.72.•••.18', 'Maintenant', true], ['smartphone', 'Application MSG · Android', 'Douala, Cameroun', '102.244.•••.7', 'il y a 2 h'], ['laptop', 'Firefox · Ubuntu', 'Yaoundé, Cameroun', '41.202.•••.95', 'jeu. 15 oct., 21:14']];
  return <BoFrame label="Sécurité du compte · sessions actives" note="Chaque session peut être fermée ; la fermeture est journalisée.">
    <Shell active="" title="Sécurité du compte" crumb="Mon compte" acts={<Btn v="outline">Déconnecter les autres sessions</Btn>}>
      <Panel title="Sessions actives · 3"><div className="tbl-wrap"><table className="tbl"><thead><tr><th>Appareil</th><th>Lieu</th><th>Adresse IP</th><th>Dernière activité</th><th></th></tr></thead><tbody>
        {s.map(([ic, d, l, ip, t, cur]) => <tr key={d}><td><span className="who"><DS.IconChip tint="green" size={36} icon={<I name={ic} size={18} />} /><b>{d}</b></span></td><td>{l}</td><td className="muted tnum">{ip}</td><td>{t}</td><td style={{ textAlign: 'right' }}>{cur ? <DS.Badge tone="green">Cette session</DS.Badge> : <Btn v="ghost" size="sm" style={{ padding: '0 12px', minHeight: 40 }}>Déconnecter</Btn>}</td></tr>)}</tbody></table></div></Panel>
      <div className="bo-cols half"><Panel title="Double authentification" pad><div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}><St s="ok">Activée · SMS au +237 6•• •• •• 41</St><Btn v="secondary" size="sm">Changer</Btn></div></Panel>
        <Panel title="Codes de secours" pad><div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}><span style={{ fontSize: 14 }}>8 codes restants sur 10</span><Btn v="secondary" size="sm">Régénérer</Btn></div></Panel></div>
    </Shell></BoFrame>;
}
function BDash() {
  const req = [['Kotto Hervé', 'Censeur du jour', 'demandé par Eboa L. · pour le 25 oct.'], ['Bilong Steve', 'Chef de groupe', 'demandé par Ewane B. · Saint-Tarcisius']];
  const acts = [['shield', 'Rôle « Formateur » : permission Planning › Modifier ajoutée', 'Ngo Nyemb C.', '10:41'], ['user-x', 'Moukouri D. suspendue', 'Tchakounté A.', 'hier 17:02'], ['key-round', 'PIN réinitialisé pour Essomba K.', 'Tchakounté A.', 'hier 16:30'], ['file-down', 'Export du livre de caisse T3 (PDF)', 'Tchoumi A.', 'lun. 09:15']];
  return <BoFrame label="Tableau de bord · super admin" note="Les montants financiers sont masqués pour le super admin : accès non accordé (séparation des tâches).">
    <Shell active="dash" title="Tableau de bord" crumb="lundi 19 octobre 2026" acts={<Btn v="secondary"><I name="user-plus" size={18} />Nouvel utilisateur</Btn>}>
      <div className="kpis"><div className="kpi"><span>Utilisateurs actifs</span><b>48</b><small>dont 5 diaspora · 1 suspendu</small></div><div className="kpi alert"><span>Demandes de rôle</span><b>2</b><small>en attente de validation</small></div><div className="kpi"><span>Mandats à échéance</span><b>0</b><small>bureau jusqu’au 30 sept. 2027</small></div><div className="kpi"><span>Super admins</span><b>2</b><small>minimum requis : 2</small></div></div>
      <div className="bo-cols">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Panel title="Demandes de rôle" acts={<a>Tout voir</a>}><div className="list">{req.map(([n, r, s]) => <Row key={n} lead={<DS.Avatar name={n} size={40} />} title={<span style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>{n}<RoleBadge t={r === 'Censeur du jour' ? 'temp' : ''}>{r}</RoleBadge></span>} sub={s} end={<div style={{ display: 'flex', gap: 8 }}><Btn v="secondary" size="sm">Refuser</Btn><Btn size="sm">Approuver</Btn></div>} />)}</div></Panel>
          <Panel title="Actions sensibles récentes" acts={<a>Journal d’audit</a>}><div className="list">{acts.map(([ic, t, w, h]) => <Row key={t} lead={<DS.IconChip tint="purple" size={36} icon={<I name={ic} size={18} />} />} title={t} sub={w} end={<span className="muted" style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{h}</span>} />)}</div></Panel>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Panel title="Système et synchronisation" pad><div className="dl" style={{ gridTemplateColumns: 'minmax(0,1fr) auto' }}>
            <dt>Serveur</dt><dd><St s="ok">Opérationnel</St></dd><dt>Synchronisation mobile</dt><dd><St s="warn">4 appareils en retard</St></dd><dt>File d’envoi</dt><dd className="tnum">12 éléments</dd><dt>Dernière sauvegarde</dt><dd>aujourd’hui 03:00</dd><dt>Version de l’app</dt><dd className="tnum">1.0.3 · 46 sur 48 à jour</dd></div></Panel>
          <Panel title="Finances" pad><div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}><span style={{ fontSize: 14, color: 'var(--text-secondary)' }}>Solde de la caisse</span><Masked /><span style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.45 }}>Visible par le trésorier, le commissaire aux comptes et le président.</span></div></Panel>
        </div></div>
    </Shell></BoFrame>;
}
function UserRows({ sel = [] }) {
  return <tbody>{USERS.map(([n, ph, s, st, roles, g, last], i) => <tr key={n} className={sel.includes(i) ? 'sel' : ''}><td><Cbx on={sel.includes(i)} /></td><td><span className="who"><DS.Avatar name={n} size={36} /><b>{n}</b></span></td><td className="tnum muted">{ph}</td><td><St s={s}>{st}</St></td><td><span className="rbs">{roles.map(([t, r, u]) => <RoleBadge key={r} t={t} until={u}>{r}</RoleBadge>)}</span></td><td className="muted">{g}</td><td className="muted">{last}</td></tr>)}</tbody>;
}
function BUsers() {
  return <BoFrame label="Utilisateurs · liste" note="Tableau filtrable ; sélection multiple pour suspendre, réinitialiser le PIN ou exporter.">
    <Shell active="users" title="Utilisateurs" crumb="49 comptes" acts={<><Btn v="outline"><I name="file-spreadsheet" size={18} />Importer</Btn><Btn><I name="user-plus" size={18} />Nouvel utilisateur</Btn></>}>
      <Panel><div className="filters"><DS.SearchInput placeholder="Nom, téléphone…" /><FSel on>Statut : tous sauf archivés</FSel><FSel>Rôle</FSel><FSel>Groupe</FSel><FSel>Diaspora</FSel><a style={{ fontSize: 13, marginLeft: 'auto' }}>Réinitialiser</a></div>
        <div className="bulk"><span>2 sélectionnés</span><div className="acts"><button>Réinitialiser le PIN</button><button>Suspendre</button><button>Exporter</button></div></div>
        <div className="tbl-wrap"><table className="tbl"><thead><tr><th><Cbx /></th><th>Nom</th><th>Téléphone</th><th>Statut</th><th>Rôles</th><th>Groupe</th><th>Dernière connexion</th></tr></thead><UserRows sel={[4, 5]} /></table></div>
        <div className="tbl-f"><span>1–9 sur 49</span><div className="pg"><IconBtn icon="chevron-left" label="Précédent" /><IconBtn icon="chevron-right" label="Suivant" /></div></div></Panel>
    </Shell></BoFrame>;
}
function BUserDetail({ modal }) {
  return <BoFrame label={modal ? 'Affecter un rôle · dates de début et de fin' : 'Fiche utilisateur'} note={modal ? 'Le mandat du bureau dure 2 ans : la date de fin est proposée automatiquement. Les cumuls interdits sont bloqués avant l’enregistrement.' : 'Identité, statut, groupes, rôles datés, dernière connexion. Les actions sensibles demandent confirmation.'} modal={modal}>
    <Shell active="users" title="Eboa Lionel" crumb="Utilisateurs ›" acts={<><Btn v="outline"><I name="key-round" size={18} />Réinitialiser le PIN</Btn><Btn v="outline" style={{ color: 'var(--red-500)', borderColor: 'var(--red-500)' }}>Suspendre</Btn></>}>
      <div className="bo-cols">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Panel title="Rôles" acts={<Btn size="sm"><I name="plus" size={16} />Affecter un rôle</Btn>}><div className="tbl-wrap"><table className="tbl"><thead><tr><th>Rôle</th><th>Début</th><th>Fin</th><th>Échéance</th><th></th></tr></thead><tbody>
            <tr><td><RoleBadge t="bureau">Censeur général</RoleBadge></td><td className="tnum">01/10/2025</td><td className="tnum">30/09/2027</td><td><div className="timeline" style={{ minWidth: 160 }}><div className="tl-bar"><i style={{ left: 0, width: '52%' }} /></div><div className="tl-l"><span>mandat 2 ans</span><span>reste 11 mois</span></div></div></td><td><IconBtn icon="ellipsis" label="Plus" /></td></tr>
            <tr><td><RoleBadge>Chef de groupe</RoleBadge></td><td className="tnum">15/01/2026</td><td className="muted">sans fin</td><td className="muted">—</td><td><IconBtn icon="ellipsis" label="Plus" /></td></tr>
            <tr><td><RoleBadge t="temp">Censeur du jour</RoleBadge></td><td className="tnum">17/10/2026</td><td className="tnum">17/10/2026</td><td><St s="off">Expiré automatiquement</St></td><td></td></tr></tbody></table></div></Panel>
          <Panel title="Groupes" pad><div className="rbs"><RoleBadge>Groupe Saint-Michel · chef</RoleBadge></div></Panel>
        </div>
        <Panel title="Identité" pad><dl className="dl"><dt>Téléphone</dt><dd className="tnum">+237 6 91 02 33 58</dd><dt>Statut</dt><dd><St s="ok">Actif</St></dd><dt>Membre depuis</dt><dd>dimanche 3 septembre 2017</dd><dt>Date de naissance</dt><dd>12/05/2001</dd><dt>Dernière connexion</dt><dd>aujourd’hui 07:40 · Android</dd><dt>Double auth.</dt><dd>Non requise (rôle sans accès back-office)</dd></dl></Panel>
      </div>
    </Shell></BoFrame>;
}
function AssignDialog() {
  return <div className="dialog wide" role="dialog"><h3>Affecter un rôle à Eboa Lionel</h3>
    <div className="form-grid"><Field label="Rôle" req value="Commissaire aux comptes" trailing={<I name="chevron-down" size={18} />} hint="Rôle du bureau · accès Finances en lecture et validation" /><Field label="Type" value="Mandat du bureau (2 ans)" trailing={<I name="chevron-down" size={18} />} /><Field label="Début" req value="jeudi 1er octobre 2026" icon="calendar" /><Field label="Fin" req value="jeudi 30 septembre 2027" icon="calendar" hint="Proposée : début + 2 ans − 1 jour. Rappel 30 jours avant." /></div>
    <div className="notice ok"><I name="shield-check" size={18} /><span><b>Séparation des tâches vérifiée.</b> Le commissaire aux comptes ne peut pas être trésorier ; Eboa L. n’a pas ce rôle.</span></div>
    <Field label="Motif (journalisé)" req value="Élection en assemblée générale du 3 octobre 2026" />
    <div className="acts"><Btn v="ghost" style={{ padding: '0 16px' }}>Annuler</Btn><Btn>Continuer</Btn></div></div>;
}
function BImport() {
  const rows = [['Ndjock Patrick', '+237 6 50 11 23 45', 'Saint-Tarcisius', 'ok'], ['Bilong Steve', '+237 6 70 34 56 12', 'Saint-Tarcisius', 'ok'], ['Etoundi Carine', '6 99 2', 'Sainte-Agnès', 'Téléphone incomplet'], ['Manga Yves', '+237 6 77 63 02 19', 'Saint-Michel', 'Numéro déjà utilisé (Moukouri D.)']];
  return <BoFrame label="Import en masse depuis un tableur" note="3 étapes : fichier, correspondance des colonnes, vérification. Les lignes en erreur sont exclues, jamais importées à moitié."
    modal={<div className="dialog wide"><h3>Importer des utilisateurs</h3><div className="steps3"><div className="on"><i />1. Fichier</div><div className="on"><i />2. Colonnes</div><div className="on"><i />3. Vérification</div></div>
      <div className="file"><I name="file-spreadsheet" size={20} style={{ color: 'var(--msg-green-600)' }} /><div><b>membres_rentree_2026.xlsx</b>48 lignes · feuille « Membres »</div></div>
      <div className="tbl-wrap" style={{ borderRadius: 12, boxShadow: '0 0 0 1px var(--border-subtle)' }}><table className="tbl"><thead><tr><th>Nom</th><th>Téléphone</th><th>Groupe</th><th>Contrôle</th></tr></thead><tbody>{rows.map(([n, p, g, s]) => <tr key={n} className={s === 'ok' ? '' : 'err'}><td><b>{n}</b></td><td className="tnum">{p}</td><td>{g}</td><td>{s === 'ok' ? <St s="ok">Valide</St> : <St s="err">{s}</St>}</td></tr>)}</tbody></table></div>
      <p><b style={{ color: 'var(--text-primary)' }}>46 lignes valides</b>, 2 en erreur. Rôle attribué par défaut : Membre. Chaque personne recevra un SMS pour créer son PIN.</p>
      <div className="acts"><Btn v="ghost" style={{ padding: '0 16px' }}>Télécharger les erreurs</Btn><Btn>Importer 46 utilisateurs</Btn></div></div>}>
    <Shell active="users" title="Utilisateurs" crumb="49 comptes"><Panel><div className="tbl-wrap"><table className="tbl"><thead><tr><th></th><th>Nom</th><th>Téléphone</th><th>Statut</th><th>Rôles</th><th>Groupe</th><th>Dernière connexion</th></tr></thead><UserRows /></table></div></Panel></Shell></BoFrame>;
}
Object.assign(window, { USERS, BLogin, BSessions, BDash, BUsers, BUserDetail, AssignDialog, BImport });
