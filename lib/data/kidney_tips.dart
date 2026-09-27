class KidneyTip {
  const KidneyTip({
    required this.title,
    required this.text,
    required this.short,
    required this.asset,
  });

  final String title;
  final String text;

  /// Version courte, pour les notifications.
  final String short;
  final String asset;
}

const kidneyTips = [
  KidneyTip(
    title: 'Tes reins, des filtres infatigables',
    text: 'Chaque jour, tes reins filtrent environ 180 litres de liquide pour '
        'débarrasser le corps de ses déchets. L\'eau que tu bois les aide à '
        'faire ce travail.',
    short: 'Tes reins filtrent environ 180 L par jour : aidez-les !',
    asset: 'assets/illustrations/kidney_filter.svg',
  ),
  KidneyTip(
    title: 'Calculs rénaux',
    text: 'Quand on boit trop peu, l\'urine devient très concentrée et des '
        'cristaux peuvent former des calculs, des « pierres » très douloureuses. '
        'Boire régulièrement aide à les prévenir.',
    short: 'Boire régulièrement aide à prévenir les calculs rénaux.',
    asset: 'assets/illustrations/kidney_stones.svg',
  ),
  KidneyTip(
    title: 'Infections urinaires',
    text: 'Uriner souvent chasse les bactéries de la vessie. Une bonne '
        'hydratation réduit le risque d\'infection urinaire, qui peut remonter '
        'jusqu\'aux reins.',
    short: 'L\'eau aide à chasser les bactéries des voies urinaires.',
    asset: 'assets/illustrations/bladder_infection.svg',
  ),
  KidneyTip(
    title: 'Attention à la déshydratation',
    text: 'Une forte déshydratation (diarrhée, vomissements, fièvre, grosse '
        'chaleur) peut abîmer les reins brutalement : c\'est l\'insuffisance '
        'rénale aiguë. Bouche sèche, vertiges, très peu d\'urine ? Bois et '
        'consulte un médecin.',
    short: 'La déshydratation fatigue tes reins. Un peu d\'eau maintenant !',
    asset: 'assets/illustrations/kidney_tired.svg',
  ),
  KidneyTip(
    title: 'Quand il fait chaud',
    text: 'Par forte chaleur ou après un effort, on perd beaucoup d\'eau en '
        'transpirant. Bois sans attendre d\'avoir soif : la soif est déjà un '
        'signal d\'alarme.',
    short: 'Il fait chaud ? N\'attends pas d\'avoir soif pour boire.',
    asset: 'assets/illustrations/sun_heat.svg',
  ),
  KidneyTip(
    title: 'Regarde la couleur',
    text: 'Une urine jaune pâle montre que tu es bien hydraté. Si elle est '
        'foncée, il est temps de boire.',
    short: 'Urine foncée = il est temps de boire.',
    asset: 'assets/illustrations/urine_colors.svg',
  ),
  KidneyTip(
    title: 'Tension et diabète',
    text: 'L\'hypertension et le diabète sont les premières causes de maladie '
        'rénale chronique, souvent silencieuse pendant des années. Fais '
        'contrôler ta tension, ton sucre et tes reins régulièrement.',
    short: 'Tension et diabète abîment les reins : fais-toi dépister.',
    asset: 'assets/illustrations/blood_pressure.svg',
  ),
  KidneyTip(
    title: 'Prudence avec les médicaments',
    text: 'Les anti-inflammatoires (ibuprofène, diclofénac…) pris souvent ou '
        'sans avis médical peuvent abîmer les reins, surtout quand on boit peu. '
        'Évite l\'automédication.',
    short: 'Évite l\'automédication : certains médicaments abîment les reins.',
    asset: 'assets/illustrations/pills_warning.svg',
  ),
  KidneyTip(
    title: 'Des reins en forme',
    text: 'Boire de l\'eau tout au long de la journée, manger moins salé et '
        'bouger : de petits gestes qui protègent tes reins pour longtemps.',
    short: 'Un verre d\'eau, et tes reins te disent merci !',
    asset: 'assets/illustrations/kidney_happy.svg',
  ),
];

const healthDisclaimer =
    'Ces conseils ne remplacent pas l\'avis d\'un médecin. Si tu as une '
    'maladie des reins ou du cœur, demande à ton médecin quelle quantité '
    'boire : elle doit parfois être limitée.';

/// Conseil associé à une alerte : le même dans la notification et dans l'appli.
int tipIndexFor(int weekday, int slotIndex) =>
    (weekday * 8 + slotIndex) % kidneyTips.length;

/// Le message qui fait réagir, répété dans chaque alerte.
const kidneyPriceMessage =
    'Une greffe de rein coûte plus de 15 000 000 FCFA. L\'eau, elle, est '
    'presque gratuite !';
