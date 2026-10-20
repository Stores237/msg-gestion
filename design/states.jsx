function SOffline() {
  return <Phone label="Hors ligne · saisies en attente" note="Bandeau permanent + indicateur de dernière synchronisation. Rien n’est perdu." role="tresorier" active="finances" net="offline">
    <NetBar pending={2} />
    <AppBar title="Finances" sync="offline" />
    <div className="scroll" style={{ gap: 16 }}>
      <div className="notice"><I name="info" size={18} /><span>Le solde affiché date d’hier, 18:05. Vos nouvelles saisies seront envoyées dès le retour du réseau.</span></div>
      <div className="card list">{BOOK.slice(0, 2).map((r, i) => <BookRow key={i} r={[r[0], r[1], r[2], r[3], 'local', r[5]]} />)}</div>
    </div>
  </Phone>;
}
function SSyncError() {
  return <Phone label="Synchronisation · erreur" note="Ligne de synchro en accent d’alerte + toast avec action." role="tresorier" active="accueil"
    toast={<Toast icon="triangle-alert" action="Réessayer">Envoi impossible. Réseau trop faible.</Toast>}>
    <AppBar logo title="Bonjour Ingrid" sub="Trésorière" sync="error" actions={<IconBtn icon="bell" label="Notifications" />} />
    <div className="scroll"><div className="msg-stat"><DS.StatRow stats={[{ value: '186 500', label: 'Solde (FCFA)' }, { value: '41', label: 'Membres actifs' }, { value: '3', label: 'À valider' }]} /></div>
      <div className="card list"><Row lead={<DS.IconChip tint="green" size={40} icon={<I name="refresh-cw" />} />} title="Synchronisation en cours…" sub="3 sur 5 éléments envoyés" /></div></div>
  </Phone>;
}
function SRestricted() {
  return <Phone label="Accès réservé · Finances" note="Ouvert depuis un lien : le contenu n’est pas chargé, la raison est expliquée." role="censeur" active="accueil">
    <AppBar back title="Livre de caisse" small sync={null} />
    <div className="scroll" style={{ justifyContent: 'center' }}>
      <EmptyState icon="lock" title="Accès réservé" text="Le livre de caisse est consulté par le trésorier, le commissaire aux comptes et le président." action={<Btn v="secondary">Retour à l’accueil</Btn>} />
    </div>
  </Phone>;
}
function SEmpty() {
  return <Phone label="Annonces · vide" note="État vide : ce qui se passera, sans illustration." role="membre" active="annonces">
    <AppBar title="Annonces" />
    <div className="scroll" style={{ gap: 12 }}>
      <DS.SegmentedTabs options={['Toutes', 'Convocations', 'Non lues']} active={2} onChange={() => { }} />
      <EmptyState icon="inbox" title="Tout est lu" text="Les nouvelles annonces et convocations du bureau apparaîtront ici." />
    </div>
  </Phone>;
}
function SError() {
  return <Phone label="Membres · erreur de chargement" note="Erreur avec cause probable et action unique." role="sg" active="membres">
    <AppBar title="Membres" sync="error" />
    <div className="scroll" style={{ justifyContent: 'center' }}>
      <EmptyState err icon="cloud-alert" title="Liste non chargée" text="La connexion a été coupée pendant le chargement. Les 42 membres déjà enregistrés sur ce téléphone restent consultables." action={<div style={{ display: 'flex', gap: 8 }}><Btn>Réessayer</Btn><Btn v="secondary">Voir hors ligne</Btn></div>} />
    </div>
  </Phone>;
}
function SDialog() {
  return <Phone label="Dialogue · validation (commissaire)" note="Confirmation explicite ; l’action est tracée avec nom et heure." role="cac" active="finances"
    overlay={<Dialog title="Valider cette opération ?" acts={<><Btn v="ghost" style={{ padding: '0 16px' }}>Annuler</Btn><Btn>Valider</Btn></>}>
      <div className="card list" style={{ boxShadow: 'none', background: 'var(--surface-sunken)' }}><Row title="Contribution décès · Nkotto" sub="Essomba Kévin · saisi par Fotso I." end={<Amt v={2500} />} /></div>
      <p>Votre nom et l’heure seront enregistrés. Une opération validée ne peut plus être modifiée.</p></Dialog>}>
    <AppBar title="Finances" />
  </Phone>;
}
Object.assign(window, { SOffline, SSyncError, SRestricted, SEmpty, SError, SDialog });
