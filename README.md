# Bois & Vis 💧

Application Flutter (Android et iOS) qui rappelle de boire de l'eau **toutes les 2 heures, de 7h à 20h**
(7h, 9h, 11h, 13h, 15h, 17h, 19h), avec des illustrations qui sensibilisent aux maladies des reins.

## Fonctionnalités

Design façon jeu (style Duolingo) : couleurs vives, boutons en relief, police **Plus Jakarta Sans**,
et **Reno**, le rein mascotte, qui guide et encourage.

- **Compte** : accueil, inscription (prénom, e-mail, mot de passe), connexion, mot de passe oublié.
  La progression est sauvegardée en ligne et retrouvée sur un autre téléphone.
- **Paramètres** : changer son prénom, modifier ses alertes, faire sonner un essai, se déconnecter,
  supprimer son compte.
- **Après l'inscription, une question par écran** : prénom et e-mail, quantité d'eau bue par jour
  (moins de 1 L, environ 1,5 L, environ 2 L, plus de 2 L), difficultés (oubli, pas envie, pas d'eau
  à côté, trop occupé), puis les alertes.
- **Alertes** : toutes les 2 h ou toutes les 3 h (de 7h à 20h), ou à des heures précises avec la
  quantité de chacune (ex. 9h 0,5 L, 12h 0,5 L…), 8 alertes au plus.
- **Le téléphone sonne** comme un réveil : « Awa, lève-toi et bois ton eau ! », avec la quantité et
  le message « Une greffe de rein coûte plus de 15 000 000 FCFA ».
- **Parcours du jour** : les alertes en zigzag, à cocher. L'étape en cours s'ouvre à l'heure de
  l'alerte, les oubliées peuvent être rattrapées, les suivantes sont verrouillées.
- **XP et niveaux** : +10 XP par alerte cochée, +30 XP pour une journée parfaite, +5 XP par leçon lue.
- **Flamme** : jours d'affilée avec au moins 70 % des alertes cochées.
- **Mon évolution** (onglet Profil) : courbe du mois (litres bus chaque jour) et de l'année
  (moyenne par jour, mois par mois), avec l'objectif en pointillés ; toucher la courbe pour lire une valeur.
- **Badges**, **leçons illustrées** sur les reins et **profil** (statistiques, modifier ses alertes).

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
