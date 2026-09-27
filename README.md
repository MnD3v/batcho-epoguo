# Bois & Vis 💧

Application Flutter (Android et iOS) qui rappelle de boire de l'eau **toutes les 2 heures, de 7h à 20h**
(7h, 9h, 11h, 13h, 15h, 17h, 19h), avec des illustrations qui sensibilisent aux maladies des reins.

## Fonctionnalités

Design façon jeu (style Duolingo) : couleurs vives, boutons en relief, police **Plus Jakarta Sans**,
et **Reno**, le rein mascotte, qui guide, encourage et **parle** (bouton 🔊, voix du téléphone).

- **On commence sans compte** : prénom, quantité bue par jour, difficultés, alertes. Le compte
  (e-mail et mot de passe) est proposé après la première gorgée, et garde la progression déjà faite.
- **Alertes riches** (awesome_notifications) : image de Reno ou du conseil du jour, boutons
  **« J'ai bu ✓ »** (coche sans ouvrir l'appli) et **« Plus tard (15 min) »**. Son doux par défaut,
  **fort (réveil)** au choix. Messages variés, dont « une greffe de rein coûte plus de 15 000 000 FCFA ».
  Rappel du soir quand la flamme est en danger.
- **Rythme** : toutes les 2 h ou 3 h (7h–20h), ou à des heures précises avec la quantité de chacune.
- **Widget Android** : litres bus, jauge, flamme et bouton « J'ai bu ✓ ».
- **Parcours du jour** en zigzag, **XP et niveaux**, **flamme** (70 % des alertes cochées),
  **jours de repos** qui protègent la flamme (1 gagné tous les 7 jours, 2 au plus), paliers 7/30/100 jours,
  **badges**, **leçons illustrées** sur les reins.
- **Amis** : défis de la semaine par code (classement des litres), parrainage (+50 XP chacun),
  partage d'une image sur WhatsApp.
- **Mode chaleur** : ville choisie dans une liste (sans GPS) ; au-delà de 35 °C, Reno conseille 2 verres de plus.
- **Profil** : courbes mensuelle et annuelle, statistiques ; **paramètres** : prénom, alertes, son,
  ville, déconnexion, suppression du compte.

Les données sont gardées sur le téléphone (`shared_preferences`) et sauvegardées dans Firestore,
dans `users/{uid}` : prénom, e-mail, réponses au questionnaire en clair (lisibles dans la console
Firebase), et toute la progression dans `data`.

## Firebase

Projet Firebase **`bois-et-vis`**, identifiant de l'appli **`com.equilibre.boisetvis`** (Android et iOS).

- **Android** : branché (clés dans `lib/firebase_options.dart`).
- **iOS** : pas encore. Tant qu'il manque, l'appli tourne en **mode démo** sur iPhone (comptes gardés sur
  le téléphone, mention « Mode démo » sur l'accueil). Pour le brancher : ajouter l'appli iOS
  `com.equilibre.boisetvis` dans la console, puis `flutterfire configure --platforms=android,ios`.

Dans la [console Firebase](https://console.firebase.google.com) :
1. **Authentication → Méthode de connexion** : activer **E-mail/Mot de passe**.
2. **Firestore Database** : créer la base, puis publier les règles de `firestore.rules`
   (onglet Règles, ou `firebase deploy --only firestore:rules`).

Aucune modification Gradle n'est nécessaire : les clés sont lues depuis `lib/firebase_options.dart`.

## Lancer le projet

```bash
flutter pub get
flutter run
flutter test
```

## Organisation

| Dossier | Contenu |
| --- | --- |
| `lib/models/` | Profil, alertes (`plan.dart`), XP, niveaux et badges (`game.dart`) |
| `lib/data/` | Conseils sur les reins, sauvegarde locale |
| `lib/services/` | Alertes, connexion (Firebase ou démo), sauvegarde en ligne |
| `lib/app_root.dart` | Choix de l'écran : accueil, questionnaire ou appli |
| `lib/theme/duo.dart`, `lib/widgets/` | Couleurs, police, boutons en relief, mascotte, écrans de victoire |
| `lib/screens/` | Connexion, questionnaire, parcours, leçons, succès, profil, paramètres |
| `assets/` | Dessins SVG, police Plus Jakarta Sans (licence OFL), icône |
| `tool/generate_illustrations.py` | Script qui génère les dessins SVG et l'icône |

Pour modifier les dessins : éditer `tool/generate_illustrations.py`, lancer `python3 tool/generate_illustrations.py`,
puis pour l'icône convertir `assets/icon/app_icon.svg` en PNG 1024×1024 et lancer `dart run flutter_launcher_icons`.

> Ces conseils ne remplacent pas l'avis d'un médecin. Certaines personnes (maladie des reins ou du cœur)
> doivent limiter ce qu'elles boivent.
