# Bois & Vis 💧

Application Flutter (Android et iOS) qui rappelle de boire de l'eau **toutes les 2 heures, de 7h à 20h**
(7h, 9h, 11h, 13h, 15h, 17h, 19h), avec des illustrations qui sensibilisent aux maladies des reins.

## Fonctionnalités

- **Choix de la boisson** : pure water (sachet de 0,5 L), verre (200 à 330 ml) ou bouteille (330 ml à 1 L),
  et le nombre à boire à chaque rappel.
- **Notifications locales** à chaque créneau, avec un conseil différent selon le jour et l'heure.
- **Cocher les rappels** : un simple coche par créneau, la jauge d'eau montre le total bu et l'objectif du jour.
- **Conseils illustrés** sur les reins : calculs rénaux, infections urinaires, déshydratation, chaleur,
  couleur de l'urine, tension et diabète, médicaments.

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
| `lib/models/` | Boissons et quantités |
| `lib/data/` | Créneaux de rappel, conseils sur les reins, sauvegarde locale |
| `lib/services/` | Programmation des notifications |
| `lib/screens/`, `lib/widgets/` | Écrans (choix de la boisson, accueil) et composants |
| `assets/illustrations/`, `assets/drinks/` | Dessins SVG |
| `tool/generate_illustrations.py` | Script qui génère les dessins SVG et l'icône |

Pour modifier les dessins : éditer `tool/generate_illustrations.py`, lancer `python3 tool/generate_illustrations.py`,
puis pour l'icône convertir `assets/icon/app_icon.svg` en PNG 1024×1024 et lancer `dart run flutter_launcher_icons`.

> Ces conseils ne remplacent pas l'avis d'un médecin. Certaines personnes (maladie des reins ou du cœur)
> doivent limiter ce qu'elles boivent.
