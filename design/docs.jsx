const COLORS = [
  ['Primaire', '--msg-green-500', '#2E7D46', '#2E7D46', 'Boutons, onglet actif, cases cochées'],
  ['Primaire texte', '--msg-green-600', '#256A3A', '#7CC795', 'Liens, montants entrants'],
  ['Primaire teinte', '--msg-green-100', '#DCEBE0', '#1E3426', 'Fond de puce « Actif », bouton secondaire'],
  ['Fond', '--surface-bg', '#F6F3EE', '#151412', 'Fond d’écran, blanc cassé chaud'],
  ['Surface', '--surface-card', '#FFFFFF', '#1F1D1A', 'Cartes, feuilles, champs'],
  ['Surface creuse', '--surface-sunken', '#F1EDE6', '#282521', 'Blocs de date, notices, pistes'],
  ['Filet', '--border-subtle', '#E3DDD2', '#35322D', 'Séparateurs de lignes, bord des champs'],
  ['Texte', '--text-primary', '#262420', '#F1EDE6', 'Anthracite chaud'],
  ['Texte secondaire', '--text-secondary', '#5F5A52', '#BDB6AA', 'Sous-titres, métadonnées'],
  ['Texte tertiaire', '--text-tertiary', '#736C61', '#A39C90', 'Chevrons, placeholders (≥ 4,5:1)'],
  ['Alerte', '--red-500', '#B3502B', '#E5845F', 'Seul accent : erreurs, non lus, absent'],
  ['Attention', '--amber-600', '#7A5A12', '#E0BE73', 'À payer, à valider, en congé (sur teinte)'],
];
function Sw({ name, v, hex, sub }) { return <div className="sw"><i style={{ background: hex }} /><div><b>{name}</b><code>{v}</code><br /><code>{hex}</code>{sub && <><br />{sub}</>}</div></div>; }
function Tokens() {
  const type = [['Display', 28, 800, 'Bienvenue'], ['Titre 1', 22, 800, 'Finances'], ['Titre 2', 19, 800, 'Valider cette opération ?'], ['Titre 3', 17, 800, 'octobre 2026'], ['Corps', 16, 400, 'Rendez-vous jeudi à 18:00 à l’église.'], ['Ligne · titre', 15, 700, 'Essomba Kévin'], ['Petit', 13, 400, 'Saisi par Fotso I. · 10:12'], ['Étiquette', 12, 700, 'PROCHAIN RENDEZ-VOUS']];
  return <section className="doc-sec" id="tokens"><h2>1. Tokens</h2>
    <p className="lead">Les composants viennent du système Spekooh ; ses variables sont redéfinies sur le vert du mouvement. Pas de dégradé : le jeton de dégradé primaire est un aplat vert. Une seule couleur d’alerte.</p>
    <h3 className="doc-sub">Couleurs · clair et sombre</h3>
    <table className="tok-table"><thead><tr><th>Rôle</th><th>Clair</th><th>Sombre</th><th>Usage</th></tr></thead><tbody>
      {COLORS.map(([n, v, l, d, u]) => <tr key={v}><td><b>{n}</b><br /><code>{v}</code></td><td><span style={{ display: 'flex', gap: 8, alignItems: 'center' }}><i style={{ width: 28, height: 28, borderRadius: 8, background: l, boxShadow: '0 0 0 1px rgba(0,0,0,.1)' }} /><code>{l}</code></span></td><td><span style={{ display: 'flex', gap: 8, alignItems: 'center' }}><i style={{ width: 28, height: 28, borderRadius: 8, background: d, boxShadow: '0 0 0 1px rgba(0,0,0,.1)' }} /><code>{d}</code></span></td><td style={{ color: 'var(--text-secondary)' }}>{u}</td></tr>)}
    </tbody></table>
    <h3 className="doc-sub">Typographie</h3>
    <div className="spec"><p className="note">Plus Jakarta Sans (police du système). Corps à 16 px minimum dans les formulaires ; chiffres tabulaires (<code>font-variant-numeric: tabular-nums</code>) pour tous les montants, heures et compteurs.</p>
      <table className="tok-table"><tbody>{type.map(([n, s, w, t]) => <tr key={n}><td style={{ width: 160 }}><b>{n}</b><br /><code>{s}px · {w}</code></td><td style={{ fontSize: s, fontWeight: w, letterSpacing: n === 'Étiquette' ? '.06em' : 0 }}>{t}</td></tr>)}
        <tr><td><b>Montant</b><br /><code>tabular-nums</code></td><td><div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-end', width: 160 }}><Amt v={2500} size={17} /><Amt v={186500} size={17} /><Amt v={-12000} sign size={17} /></div></td></tr></tbody></table></div>
    <div className="doc-grid" style={{ marginTop: 24 }}>
      <div className="spec"><h3>Espacement · grille de 8</h3><div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>{[[4, 'demi-pas, icône ↔ texte'], [8, 'dans un groupe'], [16, 'marge d’écran, padding carte'], [24, 'entre sections'], [32, ''], [48, 'cible tactile minimale']].map(([s, u]) => <div key={s} style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 13 }}><code style={{ width: 36 }}>{s}</code><i style={{ height: 12, width: s * 2, background: 'var(--msg-green-500)', borderRadius: 3 }} /><span style={{ color: 'var(--text-secondary)' }}>{u}</span></div>)}</div></div>
      <div className="spec"><h3>Rayons</h3><div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>{[['sm', 8], ['md', 12], ['lg', 18], ['xl', 22], ['pill', 999]].map(([n, r]) => <div key={n} style={{ display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'center', fontSize: 12 }}><i style={{ width: 56, height: 56, borderRadius: r, boxShadow: 'inset 0 0 0 2px var(--msg-green-500)' }} /><code>{n} · {r === 999 ? '∞' : r}</code></div>)}</div><p className="note">Champs et pastilles <b>md</b>, cartes <b>lg</b>, dialogues <b>xl</b>, boutons et filtres <b>pill</b>.</p></div>
      <div className="spec"><h3>Élévation</h3><div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>{[['0', 'none', 'Lignes, champs'], ['1', 'var(--shadow-card)', 'Cartes'], ['2', 'var(--shadow-sheet)', 'Feuilles'], ['3', 'var(--shadow-dialog)', 'Dialogues, toast']].map(([n, s, u]) => <div key={n} style={{ display: 'flex', flexDirection: 'column', gap: 6, fontSize: 12, width: 72 }}><i style={{ height: 56, borderRadius: 12, background: 'var(--surface-card)', boxShadow: s }} /><code>e{n}</code><span style={{ color: 'var(--text-secondary)' }}>{u}</span></div>)}</div><p className="note">En sombre, les ombres deviennent un filet de 1 px.</p></div>
    </div>
  </section>;
}
function Spec({ title, children, note, h }) { return <div className="spec"><h3>{title}</h3><div className="stage" style={{ minHeight: h }}>{children}</div><p className="note">{note}</p></div>; }
function Components() {
  return <section className="doc-sec" id="composants"><h2>2. Composants</h2>
    <p className="lead">Boutons, badges, pastilles d’icône, lignes, avatars, recherche, interrupteur, filtres, statistiques et barre d’onglets sont ceux du système. Les composants propres à MSG sont assemblés à partir de ces pièces.</p>
    <div className="doc-grid">
      <Spec title="Boutons" note={<><b>Primaire</b> : une seule action principale par écran, pleine largeur en bas des formulaires. <b>Secondaire</b> pour les actions voisines, <b>contour</b> pour vérifier/exporter, <b>texte</b> pour annuler. Hauteur ≥ 48 dp.</>}>
        <Btn full>Enregistrer</Btn><div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}><Btn v="secondary">Appeler</Btn><Btn v="outline">Exporter</Btn><Btn v="ghost" style={{ padding: '0 12px' }}>Annuler</Btn></div><Btn full style={{ opacity: .5 }}>Désactivé</Btn></Spec>
      <Spec title="Champs de saisie" note={<>Libellé toujours visible au-dessus (jamais seulement en placeholder). Erreur : bord rouge + icône + phrase qui dit quoi faire. Texte 16 px pour éviter le zoom.</>}>
        <Field label="Nom et prénoms" req value="Ndjock Patrick" /><Field label="Téléphone du parent" req placeholder="6 XX XX XX XX" error="Ce champ est obligatoire pour un mineur." /></Spec>
      <Spec title="Champ montant" note={<>Chiffres en 34 px tabulaires, devise fixe à droite, clavier numérique. Raccourcis vers les montants officiels (inscription, maladie, médaille, décès). Pas de décimales.</>}>
        <AmountField value={2500} on={2500} /></Spec>
      <Spec title="Ligne de liste" note={<>Lignes groupées dans une carte, séparées par des filets. Titre 15 px gras, sous-titre pour la trace : <b>qui a saisi, quand, qui a validé</b>. Montant aligné à droite.</>}>
        <div className="card list"><BookRow r={BOOK[2]} /><BookRow r={BOOK[0]} /></div></Spec>
      <Spec title="Avatar membre + statut" note={<>Point de statut en bas à droite, toujours doublé d’un texte ailleurs dans la ligne. Globe en haut à droite pour la diaspora : discret, même statut que les autres.</>}>
        <div style={{ display: 'flex', gap: 20, alignItems: 'center' }}><MAvatar name="Eboa Lionel" status="actif" size={48} /><MAvatar name="Mbella Grâce" status="conge" size={48} /><MAvatar name="Moukouri Danielle" status="classe" size={48} /><MAvatar name="Ateba Sandrine" status="actif" diaspora size={48} /></div></Spec>
      <Spec title="Puces de statut" note={<>Majuscules courtes, fond teinté. Vert = en règle, ocre = à faire, neutre = information. Le rouge reste réservé aux erreurs.</>}>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}><Chip s="actif" /><Chip s="conge" /><Chip s="classe" /><Chip tone="green">Payé</Chip><Chip tone="amber">À payer</Chip><Chip tone="amber">À valider</Chip><Chip tone="neutral">Mineur</Chip><Dia /></div></Spec>
      <Spec title="Carte événement" note={<>Bloc date à gauche, type en étiquette verte, puis heure, lieu, tenue. Pas de couleur par type : le type est écrit.</>}>
        <EventCard type="Service extérieur" title="Messe d’ordination" wd="dim." day="8" mon="nov." time="09:00" place="Cathédrale Saints-Pierre-et-Paul" dress="Tenue extérieure" /></Spec>
      <Spec title="Carte annonce" note={<>Catégorie, épinglage, point vert de non-lu. Une convocation affiche l’événement lié ; le compteur de lectures n’apparaît que pour l’expéditeur.</>}>
        <AnnCard cat="Convocation" catTone="green" unread title="Session extraordinaire du bureau" convoc="mercredi 28 octobre 2026 · 19:00" author="Ewane B. · Président" reads="Lu par 9 sur 12" time="10:05" /></Spec>
      <Spec title="Barre d’onglets" note={<>5 onglets au maximum ; seuls ceux autorisés par le rôle s’affichent. Cibles de 56 dp, libellé toujours visible.</>}>
        <div className="msg-tabbar" style={{ borderRadius: 12, overflow: 'hidden' }}><DS.BottomNav items={ROLE_TABS.tresorier.map(k => ({ icon: <I name={TAB_DEF[k][0]} size={22} />, label: TAB_DEF[k][1] }))} active={2} onChange={() => { }} /></div>
        <div className="msg-tabbar" style={{ borderRadius: 12, overflow: 'hidden' }}><DS.BottomNav items={ROLE_TABS.membre.map(k => ({ icon: <I name={TAB_DEF[k][0]} size={22} />, label: TAB_DEF[k][1] }))} active={0} onChange={() => { }} /></div></Spec>
      <Spec title="Filtres et bascules" note={<>Filtres défilants (système) pour les listes, avec compteur. Bascule à 2 options pour Entrée/Sortie, Mois/Agenda.</>}>
        <DS.SegmentedTabs options={['Tous 48', 'Actifs 41', 'En congé 3', 'Diaspora 5']} active={1} onChange={() => { }} /><Seg2 options={['Entrée', 'Sortie']} on={0} />
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 15, fontWeight: 700 }}>Rappel la veille <DS.Toggle checked onChange={() => { }} /></div></Spec>
      <Spec title="Feuille du bas (bottom sheet)" note={<>Pour choisir dans une liste courte ou voir un détail sans quitter l’écran. Poignée, titre, fond assombri ; se ferme au glissé ou au tap extérieur.</>}>
        <div className="sheet" style={{ boxShadow: 'var(--shadow-card)', borderRadius: 18 }}><div className="handle" /><h3>Tenue requise</h3><div className="list" style={{ padding: 0 }}>{['Tenue intérieure', 'Tenue extérieure', 'Tenue sportive'].map((t, i) => <Row key={t} lead={<span className={'radio' + (i === 0 ? ' on' : '')} />} title={t} />)}</div></div></Spec>
      <Spec title="Dialogue" note={<>Uniquement pour une décision irréversible (valider, clôturer). Titre en question, conséquence en une phrase, action principale à droite.</>}>
        <div className="dialog" style={{ boxShadow: 'var(--shadow-card)' }}><h3>Clôturer la collecte ?</h3><p>Les 14 membres restants seront notés « non payé ».</p><div className="acts"><Btn v="ghost" style={{ padding: '0 16px' }}>Annuler</Btn><Btn>Clôturer</Btn></div></div></Spec>
      <Spec title="Toast et synchronisation" note={<>Toast : confirmation brève, 4 s, avec action éventuelle. La ligne de synchro est toujours sous le titre : synchronisé, en cours, hors ligne, échec.</>}>
        <Toast stat>Paiement enregistré</Toast><Toast stat icon="cloud-off" action="Voir">Enregistré sur le téléphone</Toast>
        <div className="card pad" style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>{['ok', 'syncing', 'offline', 'error'].map(s => <SyncLine key={s} state={s} />)}</div></Spec>
      <Spec title="Bandeau hors ligne et notices" note={<>Bandeau anthracite en haut quand le réseau manque, avec le nombre de saisies en attente. Notices : info neutre, attention ocre, erreur rouge.</>}>
        <div style={{ borderRadius: 12, overflow: 'hidden' }}><NetBar pending={2} /></div>
        <div className="notice warn"><I name="triangle-alert" size={18} /><span>3 opérations restent à vérifier.</span></div></Spec>
      <Spec title="États vide, erreur, accès réservé" note={<>Vide : dire ce qui apparaîtra ici. Erreur : cause probable + une action. Accès réservé : dire qui y a accès, ne jamais charger la donnée masquée.</>}>
        <EmptyState icon="inbox" title="Aucune annonce" text="Les annonces du bureau apparaîtront ici." /><Restricted text="Contacts des mineurs : président et secrétaire général." /></Spec>
    </div>
  </section>;
}
function Roles() {
  const cols = ['Accueil', 'Membres', 'Finances', 'Calendrier', 'Annonces'];
  const rows = [['Membre', 'chiffres perso', '—', 'ses contributions*', 'lecture', 'lecture'], ['Censeurs, formateurs, conseiller', 'oui', 'lecture, sans contacts mineurs', '—', '+ appel présences', 'lecture'], ['Secrétaire général(e) et adjoint', 'oui', 'gérer', '—', 'créer', 'rédiger, convoquer'], ['Trésorier(e)', '+ solde', 'lecture', 'saisir', 'lecture', 'lecture'], ['Commissaire aux comptes', '+ solde', 'lecture', 'auditer, valider', 'lecture', 'lecture'], ['Président', 'tout', 'tout', 'lecture, approuver', 'tout', 'tout']];
  return <section className="doc-sec" id="roles"><h2>3. Navigation par rôle</h2><p className="lead">Le super admin définit les rôles et leurs droits dans le back-office ; le tableau ci-dessous montre la configuration de départ. Un onglet sans droit n’apparaît pas. Un lien profond vers une zone interdite ouvre l’état « Accès réservé ». *Pour le membre, ses contributions et amendes sont sur l’Accueil et dans « Mon compte ». Planning : formateurs, censeurs, chefs de groupe et secrétaire modifient ; les membres voient « Mes services ».</p>
    <div className="spec" style={{ overflowX: 'auto' }}><table className="tok-table matrix"><thead><tr><th>Rôle</th>{cols.map(c => <th key={c}>{c}</th>)}</tr></thead><tbody>{rows.map(r => <tr key={r[0]}><td><b>{r[0]}</b></td>{r.slice(1).map((c, i) => <td key={i} className={c === '—' ? 'n' : 'y'}>{c}</td>)}</tr>)}</tbody></table></div></section>;
}
function A11y() {
  const lists = [['Lecture et contraste', ['Texte ≥ 4,5:1 sur son fond, y compris le texte tertiaire et les puces.', 'Corps 16 px dans les formulaires, 15 px minimum dans les listes.', 'Chiffres tabulaires pour les montants et heures ; pas de montants en couleur seule.', 'Thème sombre vérifié avec les mêmes ratios.']],
    ['Toucher et gestes', ['Toute cible ≥ 48 × 48 dp (onglets 56 dp, présences 44 dp avec 4 dp d’écart).', 'Une action principale par écran, en bas, à portée du pouce.', 'Pas d’action uniquement au glissé ; toujours un bouton équivalent.', 'Clavier numérique pour téléphone, PIN et montants.']],
    ['Sens sans couleur', ['Statut : point + texte (Actif, En congé, Classé).', 'Présences : lettre P/A/E + couleur + libellé lu par TalkBack.', 'Non lu : point + compteur « Non lues 2 ».', 'Erreurs : icône + phrase, pas seulement un bord rouge.']],
    ['Réseau faible et données sensibles', ['Bandeau hors ligne + « dernière synchronisation » toujours visible.', 'Chaque saisie hors ligne marquée « pas encore envoyé ».', 'Données réservées jamais téléchargées pour un rôle non autorisé.', 'Libellés TalkBack sur toutes les icônes seules (retour, filtre, cloche).']]];
  return <section className="doc-sec" id="a11y"><h2>8. Accessibilité</h2><p className="lead">À contrôler à chaque écran, sur un téléphone Android d’entrée de gamme, en extérieur.</p>
    <div className="checklist">{lists.map(([t, l]) => <div key={t} className="spec"><h3>{t}</h3><ul>{l.map(x => <li key={x}><I name="square-check" size={18} /><span>{x}</span></li>)}</ul></div>)}</div>
    <h3 className="doc-sub">Extensions prévues (hors v1)</h3>
    <div className="spec"><p className="note">Discipline et sanctions avec recours, statistiques de présence, parrainage diaspora, inventaire du matériel. Chacune s’ajoute comme section d’un onglet existant (Membres → Discipline, Parrainage ; Calendrier → Statistiques) ou via « Mon compte → Plus », sans sixième onglet. Les données de présence et les identifiants membre/événement sont déjà communs à tous les modules.</p></div></section>;
}
Object.assign(window, { Spec, Tokens, Components, Roles, A11y });
