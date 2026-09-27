# Bois & Vis 💧

Application Flutter (Android et iOS) qui rappelle de boire de l'eau **toutes les 2 heures, de 7h à 20h**
(7h, 9h, 11h, 13h, 15h, 17h, 19h), avec des illustrations qui sensibilisent aux maladies des reins.

## Fonctionnalités

Design façon jeu (style Duolingo) : couleurs vives, boutons en relief, police **Plus Jakarta Sans**,
et **Reno**, le rein mascotte, qui guide et encourage.

- **Premier lancement, une question par écran** : prénom et e-mail, quantité d'eau bue par jour
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
- **Badges**, **leçons illustrées** sur les reins et **profil** (statistiques, modifier ses alertes).

Les données restent sur le téléphone (`shared_preferences`), rien n'est envoyé en ligne.

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
| `lib/services/` | Programmation des alertes |
| `lib/theme/duo.dart`, `lib/widgets/` | Couleurs, police, boutons en relief, mascotte, écrans de victoire |
| `lib/screens/` | Questionnaire, parcours, leçons, succès, profil |
| `assets/` | Dessins SVG, police Plus Jakarta Sans (licence OFL), icône |
| `tool/generate_illustrations.py` | Script qui génère les dessins SVG et l'icône |

Pour modifier les dessins : éditer `tool/generate_illustrations.py`, lancer `python3 tool/generate_illustrations.py`,
puis pour l'icône convertir `assets/icon/app_icon.svg` en PNG 1024×1024 et lancer `dart run flutter_launcher_icons`.

> Ces conseils ne remplacent pas l'avis d'un médecin. Certaines personnes (maladie des reins ou du cœur)
> doivent limiter ce qu'elles boivent.
