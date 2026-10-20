const ROLES_LIST = [['sys', 'Super admin', 2], ['bureau', 'Président', 1], ['bureau', 'Secrétaire général', 1], ['bureau', 'Trésorier', 1, true], ['bureau', 'Commissaire aux comptes', 1], ['bureau', 'Censeur général', 1], ['bureau', 'Formateur', 1], ['bureau', 'Conseiller', 1], ['', 'Chef de groupe', 3], ['temp', 'Censeur du jour', 1], ['', 'Membre', 34]];
const TRESO = [
  { mod: 'Membres' }, { n: 'Fiches membres', v: [1, 0, 0, 'n', 0, 0] }, { n: 'Contacts des mineurs', s: 'Données sensibles', v: [0, 'n', 0, 'n', 'n', 0] },
  { mod: 'Finances' }, { n: 'Livre de caisse', v: [1, 1, 1, 'l', 0, 1] }, { n: 'Contributions de solidarité', v: [1, 1, 1, 'l', 0, 1] }, { n: 'Rapport trimestriel', v: [1, 'n', 'n', 'l', 'n', 1] },
  { mod: 'Calendrier et planning' }, { n: 'Événements', v: [1, 0, 0, 'n', 0, 0] }, { n: 'Planning des services', v: [1, 0, 0, 0, 0, 0] },
  { mod: 'Annonces' }, { n: 'Annonces et convocations', v: [1, 'c', 0, 'n', 0, 'n'] },
  { mod: 'Back-office' }, { n: 'Utilisateurs et rôles', v: [0, 0, 0, 'n', 0, 0] },
];
function BRoles({ modal }) {
  return <BoFrame label={modal ? 'Confirmation · modification de permission' : 'Rôles · éditeur de la matrice de permissions'} note={modal ? 'Toute modification de rôle ou de permission passe par ce dialogue : différences, personnes concernées, motif obligatoire. Elle est inscrite au journal.' : 'Liste des rôles, matrice modules × actions, aperçu de l’application mobile pour ce rôle. Cadenas : bloqué par la séparation des tâches (le trésorier ne valide pas sa propre caisse).'}
    modal={modal && <div className="dialog" role="dialog"><h3>Enregistrer la modification ?</h3><p>Rôle <b style={{ color: 'var(--text-primary)' }}>Trésorier</b> · concerne 1 personne (Fotso Ingrid). Effet à sa prochaine synchronisation.</p>
      <div className="diff"><span>Annonces › Créer</span><del>Non</del><ins>Oui</ins></div>
      <Field label="Motif (journalisé)" req value="Publier les appels à contribution de solidarité" />
      <div className="acts"><Btn v="ghost" style={{ padding: '0 16px' }}>Annuler</Btn><Btn>Confirmer</Btn></div></div>}>
    <Shell active="roles" title="Rôles et permissions" crumb="15 rôles actifs · 1 archivé" acts={<Btn><I name="plus" size={18} />Nouveau rôle</Btn>}>
      <div className="bo-cols roles">
        <Panel title="Rôles"><div className="rolelist">{ROLES_LIST.map(([t, n, c, on]) => <div key={n} className={on ? 'on' : ''}><RoleBadge t={t}>{n}</RoleBadge><small>{c}</small></div>)}<div style={{ color: 'var(--text-secondary)' }}><I name="archive" size={16} />Responsable matériel<small>archivé</small></div></div></Panel>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24, minWidth: 0 }}>
        <Panel title={<span style={{ display: 'flex', gap: 10, alignItems: 'center' }}>Trésorier <RoleBadge t="bureau">Bureau · mandat 2 ans</RoleBadge></span>} acts={<><Btn v="ghost" size="sm" style={{ padding: '0 10px' }}>Renommer</Btn><Btn v="ghost" size="sm" style={{ padding: '0 10px' }}>Dupliquer</Btn><Btn v="ghost" size="sm" style={{ padding: '0 10px' }}>Archiver</Btn><Btn size="sm">Enregistrer 1 modification</Btn></>}>
          <PermMatrix rows={TRESO} />
          <div className="notice" style={{ margin: '0 20px 20px' }}><I name="lock" size={18} /><span>Règles fixes : le trésorier saisit, le commissaire aux comptes valide. Le super admin gère les accès sans voir les montants, sauf autorisation explicite.</span></div></Panel>
        <Panel title="Aperçu mobile de ce rôle" pad><div style={{ display: 'flex', gap: 24, alignItems: 'center', flexWrap: 'wrap' }}><MiniPhone role="tresorier"><div className="msg-stat"><DS.StatRow stats={[{ value: '186 500', label: 'Solde' }, { value: '3', label: 'À valider' }]} /></div><div className="card list" style={{ padding: '0 10px' }}><Row title="Livre de caisse" sub="Saisir · exporter" /><Row title="Annonces" sub="Lire · créer (nouveau)" /></div></MiniPhone>
          <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.55, margin: 0, flex: 1, minWidth: 200 }}>5 onglets visibles. Le bouton « Rédiger » apparaîtra dans Annonces après enregistrement. L’aperçu se met à jour à chaque case cochée.</p></div></Panel>
        </div>
      </div>
    </Shell></BoFrame>;
}
function BSafeguard() {
  return <BoFrame label="Garde-fou · au moins deux super admins" note="Le retrait est refusé tant qu’il resterait moins de deux super admins. Le refus est aussi journalisé."
    modal={<div className="dialog" role="alertdialog"><div style={{ width: 48, height: 48, borderRadius: 14, background: 'var(--red-100)', color: 'var(--red-500)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><I name="shield-alert" size={24} /></div><h3>Retrait impossible</h3>
      <p>Ngo Nyemb Christelle est l’une des 2 super admins. Il en faut au moins deux en permanence. Nommez d’abord un autre super admin, puis retirez ce rôle.</p>
      <div className="acts"><Btn v="ghost" style={{ padding: '0 16px' }}>Fermer</Btn><Btn>Nommer un super admin</Btn></div></div>}>
    <Shell active="users" title="Ngo Nyemb Christelle" crumb="Utilisateurs ›"><Panel title="Rôles" pad><div className="rbs"><RoleBadge t="bureau">Secrétaire générale</RoleBadge><RoleBadge t="sys">Super admin</RoleBadge></div></Panel></Shell></BoFrame>;
}
function BAssignments() {
  const rows = [['Nkoulou Paule', ['bureau', 'Conseiller'], '16/11/2024', '15/11/2026', 92, 'warn', 'dans 27 jours'], ['Ewane Brice', ['bureau', 'Président'], '01/10/2025', '30/09/2027', 52, 'ok', '11 mois'], ['Fotso Ingrid', ['bureau', 'Trésorière'], '01/10/2025', '30/09/2027', 52, 'ok', '11 mois'], ['Kotto Hervé', ['temp', 'Censeur du jour'], '25/10/2026', '25/10/2026', 0, 'off', 'expire à 23:59'], ['Bilong Steve', ['', 'Chef de groupe'], '01/02/2026', '—', 0, 'none', 'sans fin']];
  return <BoFrame label="Affectations de rôles · échéances" note="Une personne peut avoir plusieurs rôles, chacun daté. Alerte 30 jours avant la fin d’un mandat ; les rôles temporaires expirent seuls.">
    <Shell active="assign" title="Affectations" crumb="62 affectations actives" acts={<><Btn v="outline"><I name="file-down" size={18} />Exporter</Btn><Btn><I name="plus" size={18} />Affecter un rôle</Btn></>}>
      <div className="notice warn"><I name="triangle-alert" size={18} /><span><b>Mandat bientôt terminé.</b> Conseiller · Nkoulou Paule · fin le dimanche 15 novembre 2026 (dans 27 jours). <a>Renouveler</a> ou <a>Désigner un successeur</a>.</span></div>
      <Panel><div className="filters"><DS.SearchInput placeholder="Nom ou rôle…" /><FSel>Rôle</FSel><FSel on>Échéance : 90 jours</FSel><FSel>Type</FSel></div>
        <div className="tbl-wrap"><table className="tbl"><thead><tr><th>Personne</th><th>Rôle</th><th>Début</th><th>Fin</th><th style={{ width: 220 }}>Durée écoulée</th><th>Statut</th></tr></thead><tbody>
          {rows.map(([n, r, a, b, p, s, l]) => <tr key={n + r[1]}><td><span className="who"><DS.Avatar name={n} size={32} /><b>{n}</b></span></td><td><RoleBadge t={s === 'warn' ? 'exp' : r[0]}>{r[1]}</RoleBadge></td><td className="tnum">{a}</td><td className="tnum">{b}</td><td>{s === 'none' || s === 'off' ? <span className="muted">—</span> : <div className="tl-bar" style={{ height: 10 }}><i className={s === 'warn' ? 'w' : ''} style={{ left: 0, width: p + '%' }} /></div>}</td><td><St s={s === 'none' ? 'ok' : s}>{l}</St></td></tr>)}</tbody></table></div></Panel>
    </Shell></BoFrame>;
}
function BAudit() {
  const L = [['19/10/2026 10:41', 'Ngo Nyemb C.', 'Permission modifiée', 'Rôle Formateur', 'Planning › Modifier : Non → Oui', 'Chrome · Windows · 154.72.•••.18'], ['19/10/2026 10:05', 'Ngo Nyemb C.', 'Convocation envoyée', 'Assemblée générale', '48 destinataires', 'Android · app 1.0.3'], ['18/10/2026 17:02', 'Tchakounté A.', 'Utilisateur suspendu', 'Moukouri Danielle', 'Motif : 3 absences non justifiées', 'Chrome · Windows'], ['18/10/2026 16:30', 'Tchakounté A.', 'PIN réinitialisé', 'Essomba Kévin', 'SMS envoyé au parent', 'Chrome · Windows'], ['18/10/2026 16:12', 'Tchakounté A.', 'Refus · garde-fou', 'Rôle Super admin', 'Retrait refusé : 2 super admins minimum', 'Chrome · Windows'], ['17/10/2026 18:05', 'Tchoumi A.', 'Opération validée', 'Livre de caisse', 'Dépense · cierges et fleurs', 'Android · app 1.0.3'], ['17/10/2026 23:59', 'Système', 'Rôle expiré', 'Censeur du jour · Eboa L.', 'Expiration automatique', '—']];
  return <BoFrame label="Journal d’audit" note="Qui, quoi, quand, depuis quel appareil. Lecture seule, filtrable, exportable. Pour le super admin, les montants restent masqués dans le détail.">
    <Shell active="audit" title="Journal d’audit" crumb="Conservation : 5 ans" acts={<><Btn v="outline"><I name="file-down" size={18} />CSV</Btn><Btn v="outline"><I name="file-down" size={18} />PDF</Btn></>}>
      <Panel><div className="filters"><DS.SearchInput placeholder="Rechercher dans le journal…" /><FSel on>Période : 7 derniers jours</FSel><FSel>Auteur</FSel><FSel>Module</FSel><FSel on>Type : actions sensibles</FSel></div>
        <div className="tbl-wrap"><table className="tbl"><thead><tr><th>Date et heure</th><th>Auteur</th><th>Action</th><th>Objet</th><th>Détail</th><th>Appareil</th></tr></thead><tbody>
          {L.map(r => <tr key={r[0] + r[2]}><td className="tnum" style={{ whiteSpace: 'nowrap' }}>{r[0]}</td><td><b>{r[1]}</b></td><td>{r[2].startsWith('Refus') ? <St s="err">{r[2]}</St> : r[2]}</td><td>{r[3]}</td><td className="muted">{r[4]}</td><td className="muted">{r[5]}</td></tr>)}</tbody></table></div>
        <div className="tbl-f"><span>7 sur 1 284 entrées</span><div className="pg"><IconBtn icon="chevron-left" label="Précédent" /><IconBtn icon="chevron-right" label="Suivant" /></div></div></Panel>
    </Shell></BoFrame>;
}
function BSettings() {
  const fees = [['Inscription', 500], ['Médaille, diplôme, sacrement', 2000], ['Maladie', 1000], ['Décès', 2500]];
  return <BoFrame label="Paramètres généraux" note="Informations du mouvement, emplacement du logo, montants, valeurs par défaut du calendrier, modèles de notification, export et sauvegarde.">
    <Shell active="settings" title="Paramètres" acts={<Btn>Enregistrer</Btn>}>
      <div className="bo-cols settings">
        <div className="settings-nav">{['Mouvement', 'Montants', 'Calendrier', 'Notifications', 'Données et sauvegarde'].map((s, i) => <div key={s} className={i === 0 ? 'on' : ''}>{s}</div>)}</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Panel title="Mouvement" pad><div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}><div style={{ display: 'flex', gap: 16, alignItems: 'center' }}><LogoSlot size={80} /><div style={{ fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.5 }}>Logo fourni plus tard.<br />PNG ou SVG, fond transparent, 512 px.<br /><a>Téléverser</a></div></div>
            <Field label="Nom" value="Mouvement Garde Suisse" /><Field label="Paroisse" value="Notre-Dame de Lourdes de Yapoma, Douala" /><Field label="Devise" value="Service – Ordre – Accueil" /></div></Panel>
          <Panel title="Montants" pad><div className="list" style={{ padding: 0 }}>{fees.map(([n, v]) => <Row key={n} title={n} end={<span className="fld-box" style={{ minHeight: 44, width: 150, justifyContent: 'flex-end' }}><span className="fld-v tnum" style={{ textAlign: 'right', fontWeight: 700 }}>{fmt(v)}</span>FCFA</span>} />)}<Row title="Recouvrement" sub="Un tiers par semaine sur un mois" end={<FSel>3 tranches</FSel>} /></div></Panel>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Panel title="Calendrier" pad><div className="list" style={{ padding: 0 }}><Row title="Assise du samedi" end={<span className="fsel tnum">samedi · 15:00</span>} /><Row title="Grande veillée" end={<span className="fsel tnum">début 22:00</span>} /><Row title="Rappel par défaut" end={<span className="fsel">la veille · 20:00</span>} /></div></Panel>
          <Panel title="Modèles de notification" pad><Field label="Nouveau service" multi value="Bonjour {prénom}, tu es de service {date} à {heure} : {poste} ({côté}). Confirme dans l’app." hint="Variables : {prénom} {date} {heure} {poste} {côté}" /></Panel>
          <Panel title="Données et sauvegarde" pad><div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}><St s="ok">Sauvegarde quotidienne à 03:00 · dernière aujourd’hui</St><div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}><Btn v="secondary" size="sm">Exporter toutes les données</Btn><Btn v="ghost" size="sm" style={{ padding: '0 10px' }}>Restaurer…</Btn></div></div></Panel>
        </div></div>
    </Shell></BoFrame>;
}
function BoComponents() {
  return <div className="doc-grid">
    <Spec title="Badge de rôle" note={<><b>Vert</b> : rôle du bureau (mandat). <b>Anthracite</b> : rôle système. <b>Pointillés + minuteur</b> : temporaire. <b>Ocre</b> : échéance dans moins de 30 jours.</>}>
      <div className="rbs"><RoleBadge t="bureau">Trésorière</RoleBadge><RoleBadge t="sys">Super admin</RoleBadge><RoleBadge>Chef de groupe</RoleBadge><RoleBadge t="temp">Censeur du jour</RoleBadge><RoleBadge t="exp" until="fin 15/11">Conseiller</RoleBadge></div></Spec>
    <Spec title="Tableau de données avec filtres" note={<>Recherche + filtres en pilules (contour vert = actif) + « Réinitialiser ». La sélection fait apparaître une barre d’actions groupées. Chiffres alignés à droite, en-tête collant.</>}>
      <div className="panel" style={{ overflow: 'hidden' }}><div className="filters" style={{ padding: 12 }}><FSel on>Statut</FSel><FSel>Rôle</FSel></div><div className="bulk" style={{ padding: '8px 12px' }}><span>1 sélectionné</span><div className="acts"><button>Suspendre</button></div></div><table className="tbl"><tbody><tr className="sel"><td><Cbx on /></td><td><b>Kotto H.</b></td><td><St s="ok">Actif</St></td></tr><tr><td><Cbx /></td><td><b>Moukouri D.</b></td><td><St s="off">Suspendu</St></td></tr></tbody></table></div></Spec>
    <Spec title="Matrice de permissions" note={<>Lignes : objets par module. Colonnes : Voir, Créer, Modifier, Valider, Supprimer, Exporter. « — » : action sans objet. Cadenas : règle fixe. Contour ocre : modifié, à confirmer.</>}>
      <div className="panel" style={{ overflow: 'hidden' }}><PermMatrix rows={TRESO.slice(3, 5)} /></div></Spec>
  </div>;
}
function DataModel() {
  const M = [['User', ['id', 'nom, téléphone', 'statut', 'diaspora', 'parentContact?', 'lastLogin'], 'Utilisateurs, fiche'], ['Role', ['id, nom', 'type : bureau | système | temporaire | standard', 'archivé'], 'Rôles'], ['Permission', ['role → module.objet', 'actions[ ]', 'locked (règle fixe)'], 'Matrice'], ['RoleAssignment', ['user, role', 'start, end?', 'motif'], 'Affectations, fiche'], ['Group', ['id, nom', 'chef → User', 'membres[ ]'], 'Planning, affecter un groupe'], ['Event', ['type, date, lieu', 'tenue', 'taille du service'], 'Calendrier, planning'], ['Assignment', ['event, poste, côté', 'user', 'statut'], 'Grille, Mes services'], ['AlbRotation', ['semaine', 'responsable (user | groupe)', 'statut'], 'Lavage des aubes'], ['SwapRequest', ['assignment', 'de → vers', 'statut, validé par'], 'Échange, demandes'], ['AuditLog', ['auteur, action, objet', 'avant → après', 'appareil, IP, date'], 'Journal d’audit']];
  return <div className="model">{M.map(([n, f, u]) => <div key={n} className="card"><b>{n}</b><ul>{f.map(x => <li key={x}>{x}</li>)}</ul><small>Écrans : {u}</small></div>)}</div>;
}
Object.assign(window, { BRoles, BSafeguard, BAssignments, BAudit, BSettings, BoComponents, DataModel });
