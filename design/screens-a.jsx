const MEMBERS = [
  ['Ewane Brice', 'Président · depuis 2016', 'actif'],
  ['Ngo Nyemb Christelle', 'Secrétaire générale · depuis 2018', 'actif'],
  ['Ateba Sandrine', 'Garde · Lyon, France', 'actif', true],
  ['Eboa Lionel', 'Censeur général · depuis 2017', 'actif'],
  ['Essomba Kévin', 'Garde · depuis 2025 · 15 ans', 'actif'],
  ['Fotso Ingrid', 'Trésorière · depuis 2019', 'actif'],
  ['Mbella Grâce', 'Garde · depuis 2021', 'conge'],
  ['Moukouri Danielle', 'Garde · depuis 2020', 'classe'],
];

function SSplash() {
  return <Phone label="Splash" note="Premier lancement : préparation des données hors ligne.">
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 16, padding: 32, textAlign: 'center' }}>
      <LogoSlot size={112} label="LOGO MSG" />
      <div style={{ fontSize: 28, fontWeight: 800, marginTop: 8, lineHeight: 1.2, whiteSpace: 'nowrap' }}>MSG Gestion</div>
      <div style={{ fontSize: 15, color: 'var(--text-secondary)', lineHeight: 1.5 }}>Mouvement Garde Suisse<br />Paroisse Notre-Dame de Lourdes de Yapoma</div>
      <div className="caps" style={{ marginTop: 8 }}>Service · Ordre · Accueil</div>
    </div>
    <div style={{ padding: '0 32px 40px', display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'center' }}>
      <div className="progress" style={{ width: 160 }}><i style={{ width: '60%' }} /></div>
      <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Préparation des données…</span>
    </div>
  </Phone>;
}
function SLogin() {
  return <Phone label="Connexion · numéro" note="Le numéro sert d’identifiant. Clavier numérique du téléphone.">
    <div className="scroll" style={{ paddingTop: 32 }}>
      <LogoSlot size={64} />
      <div><div style={{ fontSize: 26, fontWeight: 800 }}>Bienvenue</div><p style={{ margin: '8px 0 0', color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.5 }}>Connectez-vous avec le numéro de téléphone enregistré au mouvement.</p></div>
      <Field label="Numéro de téléphone" value="6 77 45 21 08" focus trailing={<I name="x" size={18} />} icon="phone" hint="Format : 6 XX XX XX XX (+237)" />
      <Btn full>Continuer</Btn>
      <div className="notice"><I name="info" size={18} /><span>Pas encore de compte ? Le secrétaire général vous inscrit lors de l’assise du samedi.</span></div>
    </div>
  </Phone>;
}
function SLoginPin() {
  return <Phone label="Connexion · code PIN (erreur)" note="4 chiffres. Après 3 erreurs, le compte est bloqué 15 min.">
    <div className="scroll" style={{ paddingTop: 16, gap: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><IconBtn icon="arrow-left" label="Retour" /><span style={{ fontSize: 14, color: 'var(--text-secondary)' }}>+237 6 77 45 21 08</span></div>
      <div style={{ textAlign: 'center' }}><div style={{ fontSize: 22, fontWeight: 800 }}>Votre code PIN</div><p style={{ margin: '6px 0 0', color: 'var(--text-secondary)', fontSize: 15 }}>Bonjour Ingrid, entrez vos 4 chiffres.</p></div>
      <Pin n={4} err />
      <div className="fld is-err" style={{ alignItems: 'center' }}><span className="fld-h"><I name="circle-alert" size={14} />Code incorrect. Il vous reste 2 essais.</span></div>
      <Keypad />
      <a style={{ textAlign: 'center', fontSize: 14, padding: 12 }}>Code oublié ?</a>
    </div>
  </Phone>;
}
function SHomeMember() {
  return <Phone label="Accueil · membre" note="Rôle Membre : 3 onglets seulement. « Mon compte » via l’avatar. Capture défilante." role="membre" active="accueil" tall>
    <AppBar logo title="Bonjour Kévin" sub="Garde · 15 ans" actions={<><IconBtn icon="bell" label="Notifications" dot /><MAvatar name="Essomba Kévin" size={40} /></>} />
    <div className="scroll">
      <section className="grp"><div className="grp-h"><span className="caps">Mon prochain service</span><a>Mes services</a></div>
        <div className="card duty"><div className="duty-top"><span className="ev-type">dim. 25 oct. · 06:30</span><DutyChip s="pend" /></div><div className="duty-t">Première centrale · Pariso</div><div className="acts"><Btn style={{ flex: 1 }}>Confirmer</Btn><Btn v="secondary" style={{ flex: 1 }}>Échanger</Btn></div></div></section>
      <section className="grp"><div className="grp-h"><span className="caps">Prochain rendez-vous</span></div>
        <EventCard type="Assise du samedi" title="Assise hebdomadaire" wd="sam." day="24" mon="oct." time="samedi 24 octobre 2026 · 15:00" place="Salle paroissiale" dress="Tenue intérieure" /></section>
      <Group label="Mes contributions" action="Tout voir">
        <Row title="Décès · famille Nkotto" sub="À verser avant le samedi 31 octobre" end={<><Amt v={2500} /><Chip tone="amber">À payer</Chip></>} />
        <Row title="Amende · retard à l’assise" sub="Assise du samedi 10 octobre" end={<><Amt v={500} /><Chip tone="amber">À payer</Chip></>} />
      </Group>
      <section className="grp"><div className="grp-h"><span className="caps">Dernière annonce</span><a>Toutes</a></div>
        <AnnCard cat="Convocation" catTone="green" unread title="Assemblée générale ordinaire" convoc="samedi 7 novembre 2026 · 15:00" author="Ngo Nyemb C. · Secrétaire générale" time="lun. 10:05" /></section>
    </div>
  </Phone>;
}
function SHomeTreso() {
  return <Phone label="Accueil · trésorière" note="Chiffres clés réservés au bureau ; « à valider » attend le commissaire aux comptes." role="tresorier" active="accueil">
    <AppBar logo title="Bonjour Ingrid" sub="Trésorière" actions={<IconBtn icon="bell" label="Notifications" dot />} />
    <div className="scroll">
      <div className="msg-stat"><DS.StatRow stats={[{ value: '186 500', label: 'Solde (FCFA)' }, { value: '41', label: 'Membres actifs' }, { value: '3', label: 'À valider' }]} /></div>
      <Group label="À suivre">
        <Row lead={<DS.IconChip tint="green" size={40} icon={<I name="heart-handshake" />} />} title="Décès · famille Nkotto" sub={<span style={{ display: 'flex', flexDirection: 'column', gap: 6 }}><span>27 sur 41 ont payé · tranche 2 sur 3</span><span className="progress"><i style={{ width: '66%' }} /></span></span>} chevron />
        <Row lead={<DS.IconChip tint="amber" size={40} icon={<I name="hourglass" />} />} title="3 opérations à valider" sub="En attente du commissaire aux comptes" chevron />
        <Row lead={<DS.IconChip tint="red" size={40} icon={<I name="calendar-x" />} />} title="2 postes non pourvus cette semaine" sub="Grand-messe du dimanche 25, 09:00" chevron />
      </Group>
      <section className="grp"><div className="grp-h"><span className="caps">Prochain rendez-vous</span><a>Calendrier</a></div>
        <EventCard type="Assise du samedi" title="Assise hebdomadaire" wd="sam." day="24" mon="oct." time="15:00" place="Salle paroissiale" /></section>
    </div>
  </Phone>;
}
function SMembers() {
  return <Phone label="Membres · liste" note="Recherche, filtres par statut, badge diaspora discret." role="sg" active="membres" toast={<Fab icon="user-plus">Ajouter</Fab>}>
    <AppBar title="Membres" sub="48 gardes · 12 au bureau" actions={<IconBtn icon="list-filter" label="Filtrer" />} />
    <div className="scroll" style={{ gap: 12 }}>
      <DS.SearchInput placeholder="Rechercher un nom, un rôle…" />
      <DS.SegmentedTabs options={['Tous 48', 'Actifs 41', 'En congé 3', 'Classés 2', 'Diaspora 5']} active={0} onChange={() => { }} />
      <div className="card list"><Row lead={<DS.IconChip tint="green" size={40} icon={<I name="shield" />} />} title="Le bureau" sub="12 rôles · mandat 2025–2027" chevron /></div>
      <div className="card list">{MEMBERS.slice(0, 6).map(([n, s, st, d]) => <Row key={n} lead={<MAvatar name={n} status={st} diaspora={d} />} title={n} sub={d ? <span style={{ display: 'flex', gap: 8 }}>{s}</span> : s} end={d ? <Dia /> : (st !== 'actif' ? <Chip s={st} /> : null)} />)}</div>
    </div>
  </Phone>;
}
function SProfile() {
  return <Phone label="Profil membre · vue secrétaire général" note="Mineur : contact parent visible pour le président et le SG uniquement." role="sg" active="membres">
    <AppBar back title="Profil" small sync="ok" actions={<IconBtn icon="pencil" label="Modifier" />} />
    <div className="scroll" style={{ gap: 20 }}>
      <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}><MAvatar name="Essomba Kévin" status="actif" size={72} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}><div style={{ fontSize: 20, fontWeight: 800 }}>Essomba Kévin</div><div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>Garde · 15 ans</div><div style={{ display: 'flex', gap: 6 }}><Chip s="actif" /><Chip tone="neutral">Mineur</Chip></div></div></div>
      <div style={{ display: 'flex', gap: 8 }}><Btn v="secondary" style={{ flex: 1 }}><I name="phone" size={18} />Appeler</Btn><Btn v="secondary" style={{ flex: 1 }}><I name="message-circle" size={18} />Message</Btn></div>
      <Group label="Informations">
        <Row title="+237 6 91 34 77 02" sub="Téléphone" />
        <Row title="dimanche 14 septembre 2025" sub="Date d’adhésion · inscription 500 FCFA payée" />
      </Group>
      <Group label="Parent ou tuteur">
        <Row lead={<DS.IconChip tint="green" size={40} icon={<I name="user-round" />} />} title="Mme Essomba Pauline" sub="Mère · +237 6 99 12 34 56" end={<IconBtn icon="phone" label="Appeler le parent" />} />
      </Group>
    </div>
  </Phone>;
}
function SProfileRestricted() {
  return <Phone label="Profil membre · accès réservé" note="Vue du formateur : contacts du mineur et finances masqués." role="censeur" active="membres">
    <AppBar back title="Profil" small />
    <div className="scroll" style={{ gap: 20 }}>
      <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}><MAvatar name="Essomba Kévin" status="actif" size={72} />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}><div style={{ fontSize: 20, fontWeight: 800 }}>Essomba Kévin</div><div style={{ fontSize: 14, color: 'var(--text-secondary)' }}>Garde · depuis 2025</div><div style={{ display: 'flex', gap: 6 }}><Chip s="actif" /></div></div></div>
      <Restricted text="Les contacts des membres mineurs sont visibles uniquement par le président et le secrétaire général." />
      <section className="grp"><div className="grp-h"><span className="caps">Contributions</span></div>
        <Restricted text="L’historique des contributions est réservé au trésorier, au commissaire aux comptes et au président." /></section>
      <Group label="Présences · 4 dernières assises"><Row title="3 présent · 1 excusé" sub="Dernière : samedi 17 octobre 2026" /></Group>
    </div>
  </Phone>;
}
function SAddMember() {
  return <Phone label="Ajouter un membre" note="Âge < 18 ans : le bloc parent devient obligatoire. Les 500 FCFA d’inscription sont saisis à la création.">
    <AppBar back title="Nouveau membre" small sync={null} />
    <div className="scroll" style={{ gap: 16 }}>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}><div className="logo-slot" style={{ width: 64, height: 64, borderRadius: '50%' }}><I name="camera" size={20} /></div><a style={{ fontSize: 15 }}>Ajouter une photo</a></div>
      <Field label="Nom et prénoms" req value="Ndjock Patrick" />
      <Field label="Date de naissance" req value="mercredi 3 mars 2010" icon="calendar" hint="16 ans · contact du parent obligatoire" />
      <Field label="Téléphone du parent ou tuteur" req placeholder="6 XX XX XX XX" focus error="Ce champ est obligatoire pour un mineur." />
      <div className="card list"><Row title="Frais d’inscription" sub="Ajouté au livre de caisse, en attente de validation" end={<Amt v={500} />} /></div>
    </div>
    <div className="footer-bar"><Btn full>Enregistrer le membre</Btn></div>
  </Phone>;
}
Object.assign(window, { MEMBERS, SSplash, SLogin, SLoginPin, SHomeMember, SHomeTreso, SMembers, SProfile, SProfileRestricted, SAddMember });
