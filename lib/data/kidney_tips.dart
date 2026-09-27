/// Une partie d'une leçon : un petit titre et quelques phrases.
class TipSection {
  const TipSection(this.heading, this.text);

  final String heading;
  final String text;
}

class KidneyTip {
  const KidneyTip({
    required this.title,
    required this.text,
    required this.short,
    required this.asset,
    this.sections = const [],
    this.keyPoints = const [],
  });

  final String title;

  /// Introduction de la leçon.
  final String text;

  /// Version courte, pour les notifications.
  final String short;
  final String asset;

  /// Le détail de la leçon, partie par partie.
  final List<TipSection> sections;

  /// « À retenir » : repris sur l'image résumé partagée.
  final List<String> keyPoints;

  /// Tout le texte, pour la lecture à voix haute.
  String get fullText => [
        '$title.',
        text,
        for (final s in sections) '${s.heading}. ${s.text}',
        if (keyPoints.isNotEmpty) 'À retenir. ${keyPoints.join('. ')}.',
      ].join(' ');
}

// Les leçons sont repérées par leur place dans la liste (leçons lues) :
// on en ajoute toujours à la fin.
const kidneyTips = [
  KidneyTip(
    title: 'Tes reins, des filtres infatigables',
    text: 'Tu as deux reins, gros comme un poing, juste sous les côtes, dans '
        'le dos. Ils travaillent jour et nuit sans jamais s\'arrêter.',
    short: 'Tes reins filtrent environ 180 L par jour : aide-les !',
    asset: 'assets/illustrations/kidney_filter.svg',
    sections: [
      TipSection(
        '180 litres filtrés chaque jour',
        'Tout ton sang passe par tes reins plusieurs dizaines de fois par '
            'jour. Ils en filtrent environ 180 litres, gardent ce qui est '
            'utile et ne rejettent que 1 à 2 litres d\'urine.',
      ),
      TipSection(
        'Bien plus qu\'un filtre',
        'Tes reins règlent aussi la quantité d\'eau et de sel du corps, '
            'aident à contrôler la tension, fabriquent une hormone qui produit '
            'les globules rouges et gardent tes os solides.',
      ),
      TipSection(
        'Pourquoi l\'eau les aide',
        'Les déchets quittent le corps dissous dans l\'eau de l\'urine. Quand '
            'tu bois assez, tes reins les évacuent sans forcer. Quand tu bois '
            'peu, ils doivent concentrer l\'urine et travaillent plus dur.',
      ),
    ],
    keyPoints: [
      'Tes reins filtrent environ 180 L de sang par jour',
      'Ils règlent l\'eau, le sel et la tension',
      'Boire régulièrement leur facilite le travail',
    ],
  ),
  KidneyTip(
    title: 'Calculs rénaux',
    text: 'Un calcul rénal est un petit caillou qui se forme dans le rein. '
        'Quand il descend vers la vessie, il provoque l\'une des douleurs les '
        'plus fortes qui soient : la colique néphrétique.',
    short: 'Boire régulièrement aide à prévenir les calculs rénaux.',
    asset: 'assets/illustrations/kidney_stones.svg',
    sections: [
      TipSection(
        'Comment ils se forment',
        'Quand on boit trop peu, l\'urine devient très concentrée. Des '
            'minéraux (calcium, acide urique…) s\'y collent entre eux et '
            'forment des cristaux, qui grossissent peu à peu.',
      ),
      TipSection(
        'Les signes',
        'Douleur violente dans le dos ou sur le côté, qui descend vers le '
            'bas-ventre, nausées, sang dans les urines. Avec de la fièvre, '
            'c\'est une urgence : va voir un médecin tout de suite.',
      ),
      TipSection(
        'Comment les éviter',
        'Boire assez pour avoir une urine claire, répartir l\'eau sur toute la '
            'journée, manger moins salé et limiter les sodas sucrés. Après un '
            'premier calcul, le risque d\'en refaire un est élevé : l\'eau '
            'devient ta meilleure alliée.',
      ),
    ],
    keyPoints: [
      'Une urine trop concentrée favorise les calculs',
      'Boire toute la journée aide à les prévenir',
      'Douleur + fièvre = urgence médicale',
    ],
  ),
  KidneyTip(
    title: 'Infections urinaires',
    text: 'Les infections urinaires sont très fréquentes, surtout chez les '
        'femmes. Brûlures en urinant, envies pressantes et fréquentes : ce sont '
        'des bactéries qui ont remonté jusqu\'à la vessie.',
    short: 'L\'eau aide à chasser les bactéries des voies urinaires.',
    asset: 'assets/illustrations/bladder_infection.svg',
    sections: [
      TipSection(
        'L\'eau, une chasse d\'eau naturelle',
        'Chaque fois que tu urines, tu chasses une partie des bactéries de la '
            'vessie. Boire assez, c\'est uriner plus souvent, et laisser moins '
            'de temps aux microbes pour s\'installer.',
      ),
      TipSection(
        'Quand ça devient grave',
        'Si l\'infection remonte jusqu\'aux reins, c\'est une pyélonéphrite : '
            'fièvre, frissons, douleur dans le dos. Elle doit être soignée '
            'rapidement par un médecin.',
      ),
      TipSection(
        'Les bons gestes',
        'Bois régulièrement, ne te retiens pas d\'uriner, urine après les '
            'rapports sexuels et essuie-toi d\'avant en arrière. Et pas '
            'd\'antibiotiques sans ordonnance.',
      ),
    ],
    keyPoints: [
      'Uriner souvent chasse les bactéries',
      'Ne te retiens pas d\'aller aux toilettes',
      'Fièvre + douleur dans le dos : consulte vite',
    ],
  ),
  KidneyTip(
    title: 'Attention à la déshydratation',
    text: 'On se déshydrate quand on perd plus d\'eau qu\'on n\'en boit : '
        'chaleur, effort, diarrhée, vomissements ou fièvre. Les reins sont '
        'parmi les premiers à en souffrir.',
    short: 'La déshydratation fatigue tes reins. Un peu d\'eau maintenant !',
    asset: 'assets/illustrations/kidney_tired.svg',
    sections: [
      TipSection(
        'Les signes à reconnaître',
        'Soif, bouche sèche, fatigue, maux de tête, vertiges, urine foncée et '
            'rare. Chez les enfants et les personnes âgées, elle arrive plus '
            'vite et se voit moins.',
      ),
      TipSection(
        'Ce que ça fait aux reins',
        'Sans assez d\'eau, le sang arrive moins bien aux reins. Une forte '
            'déshydratation peut les bloquer brutalement : c\'est '
            'l\'insuffisance rénale aiguë, qui demande des soins urgents.',
      ),
      TipSection(
        'Que faire',
        'Bois par petites gorgées régulières. En cas de diarrhée ou de '
            'vomissements, les solutions de réhydratation orale (SRO, en '
            'pharmacie) sont plus efficaces que l\'eau seule. Si tu n\'urines '
            'presque plus, consulte.',
      ),
    ],
    keyPoints: [
      'Urine foncée et rare = signe de déshydratation',
      'Diarrhée ou vomissements : pense aux SRO',
      'Très peu d\'urine : va voir un médecin',
    ],
  ),
  KidneyTip(
    title: 'Quand il fait chaud',
    text: 'Par forte chaleur, ton corps se refroidit en transpirant. Tu peux '
        'perdre plus d\'un litre d\'eau par heure pendant un effort au soleil.',
    short: 'Il fait chaud ? N\'attends pas d\'avoir soif pour boire.',
    asset: 'assets/illustrations/sun_heat.svg',
    sections: [
      TipSection(
        'La soif arrive trop tard',
        'Quand tu as soif, ton corps a déjà commencé à manquer d\'eau. Par '
            'temps chaud, bois avant d\'avoir soif, un peu toutes les '
            '20 à 30 minutes.',
      ),
      TipSection(
        'Remplace aussi le sel',
        'La sueur emporte de l\'eau mais aussi des sels minéraux. Après un '
            'gros effort ou une longue journée au soleil, un repas normal ou '
            'une SRO aide à les remplacer.',
      ),
      TipSection(
        'Les bons réflexes',
        'Garde une bouteille d\'eau avec toi, reste à l\'ombre aux heures les '
            'plus chaudes et évite l\'alcool et les boissons très sucrées, '
            'qui hydratent mal.',
      ),
    ],
    keyPoints: [
      'Par forte chaleur, bois avant d\'avoir soif',
      'Un peu d\'eau toutes les 20 à 30 minutes',
      'Garde toujours une bouteille avec toi',
    ],
  ),
  KidneyTip(
    title: 'Regarde la couleur',
    text: 'La couleur de ton urine est un indicateur simple et gratuit : elle '
        'te dit en un coup d\'œil si tu bois assez.',
    short: 'Urine foncée = il est temps de boire.',
    asset: 'assets/illustrations/urine_colors.svg',
    sections: [
      TipSection(
        'Jaune pâle : parfait',
        'Une urine jaune clair, couleur paille, montre que tu es bien '
            'hydraté. C\'est l\'objectif.',
      ),
      TipSection(
        'Jaune foncé ou ambré : bois',
        'Plus elle est foncée, plus elle est concentrée : ton corps manque '
            'd\'eau. Bois un ou deux verres et regarde la différence.',
      ),
      TipSection(
        'Quand s\'inquiéter',
        'Certains aliments (betterave) et vitamines changent la couleur. '
            'Mais une urine rouge, brune comme du coca ou mousseuse qui dure '
            'doit être montrée à un médecin.',
      ),
    ],
    keyPoints: [
      'Jaune pâle = bien hydraté',
      'Foncée = bois un verre',
      'Rouge ou brune : consulte un médecin',
    ],
  ),
  KidneyTip(
    title: 'Tension et diabète',
    text: 'L\'hypertension et le diabète sont les deux premières causes de '
        'maladie rénale chronique. Le piège : on ne sent rien pendant des '
        'années.',
    short: 'Tension et diabète abîment les reins : fais-toi dépister.',
    asset: 'assets/illustrations/blood_pressure.svg',
    sections: [
      TipSection(
        'Comment ils abîment les reins',
        'Une tension trop forte ou trop de sucre dans le sang abîment peu à '
            'peu les tout petits vaisseaux qui filtrent le sang. Les reins '
            'perdent leur force sans faire mal.',
      ),
      TipSection(
        'Se faire dépister',
        'Fais prendre ta tension au moins une fois par an, et fais contrôler '
            'ton sucre. Une simple prise de sang (créatinine) et une analyse '
            'd\'urine montrent comment vont tes reins.',
      ),
      TipSection(
        'Protéger ses reins',
        'Moins de sel, moins de sucre, bouger au moins 30 minutes par jour, '
            'ne pas fumer, et prendre ses traitements tous les jours même '
            'quand on se sent bien.',
      ),
    ],
    keyPoints: [
      'Tension et diabète abîment les reins en silence',
      'Contrôle ta tension et ton sucre chaque année',
      'Moins de sel, moins de sucre, plus de marche',
    ],
  ),
  KidneyTip(
    title: 'Prudence avec les médicaments',
    text: 'Certains médicaments très courants peuvent abîmer les reins, '
        'surtout pris souvent, à forte dose, ou quand on boit peu.',
    short: 'Évite l\'automédication : certains médicaments abîment les reins.',
    asset: 'assets/illustrations/pills_warning.svg',
    sections: [
      TipSection(
        'Les anti-inflammatoires',
        'Ibuprofène, diclofénac, kétoprofène… soulagent vite, mais pris '
            'souvent ou sans avis médical, ils réduisent le sang qui arrive '
            'aux reins. Le risque augmente quand on est déshydraté.',
      ),
      TipSection(
        'Les produits « naturels »',
        'Certaines plantes et décoctions vendues sans contrôle peuvent aussi '
            'être toxiques pour les reins. Naturel ne veut pas dire sans '
            'danger.',
      ),
      TipSection(
        'Les bons réflexes',
        'Demande conseil à un médecin ou un pharmacien, respecte les doses, '
            'bois de l\'eau quand tu prends un traitement et signale toujours '
            'si tu as un problème de reins.',
      ),
    ],
    keyPoints: [
      'Pas d\'anti-inflammatoires sans avis médical',
      'Naturel ne veut pas dire sans danger',
      'Demande conseil au pharmacien',
    ],
  ),
  KidneyTip(
    title: 'Des reins en forme',
    text: 'Protéger ses reins, ce n\'est pas compliqué : ce sont de petits '
        'gestes répétés chaque jour qui font la différence sur des années.',
    short: 'Un verre d\'eau, et tes reins te disent merci !',
    asset: 'assets/illustrations/kidney_happy.svg',
    sections: [
      TipSection(
        'Boire tout au long de la journée',
        'Mieux vaut un verre toutes les deux heures qu\'un litre d\'un coup. '
            'C\'est exactement ce que font tes alertes Bois & Vis.',
      ),
      TipSection(
        'Manger moins salé',
        'Le sel fait monter la tension et fatigue les reins. Goûte avant de '
            'saler, limite les cubes, les conserves et la charcuterie.',
      ),
      TipSection(
        'Bouger et ne pas fumer',
        'Marcher 30 minutes par jour aide à garder une bonne tension et un '
            'poids sain. Le tabac abîme les vaisseaux, y compris ceux des '
            'reins.',
      ),
    ],
    keyPoints: [
      'Un verre d\'eau toutes les deux heures',
      'Moins de sel dans l\'assiette',
      '30 minutes de marche par jour',
    ],
  ),
  KidneyTip(
    title: 'Les bienfaits de l\'eau chaude',
    text: 'Boire de l\'eau chaude ou tiède, le matin ou après le repas, est '
        'une habitude dans beaucoup de pays. Elle hydrate exactement comme '
        'l\'eau fraîche, avec quelques petits plus.',
    short: 'Un verre d\'eau tiède le matin : doux pour le ventre.',
    asset: 'assets/illustrations/warm_water.svg',
    sections: [
      TipSection(
        'Douce pour la digestion',
        'Beaucoup de gens trouvent qu\'un verre d\'eau tiède aide leur ventre '
            'à se mettre en route le matin et soulage la sensation de '
            'lourdeur après un repas.',
      ),
      TipSection(
        'Réconfortante quand on est malade',
        'Rhume, gorge qui gratte, nez bouché : une boisson chaude apaise la '
            'gorge, et sa vapeur aide à dégager le nez. Elle aide aussi à '
            'boire assez quand on n\'a pas envie d\'eau froide.',
      ),
      TipSection(
        'Attention à la température',
        'Tiède ou chaude, oui ; brûlante, non. Les boissons très chaudes '
            '(plus de 65 °C) abîment la gorge et l\'œsophage à la longue. '
            'Laisse refroidir quelques minutes avant de boire.',
      ),
    ],
    keyPoints: [
      'L\'eau chaude hydrate autant que l\'eau fraîche',
      'Douce pour le ventre et la gorge',
      'Jamais brûlante : laisse-la tiédir',
    ],
  ),
  KidneyTip(
    title: 'Eau glacée : ce qu\'il faut savoir',
    text: 'Une eau bien fraîche fait du bien quand il fait chaud. Elle n\'est '
        'pas dangereuse pour la plupart des gens, mais glacée, elle a quelques '
        'inconvénients.',
    short: 'Eau glacée ? Fraîche, c\'est mieux : bois-la par petites gorgées.',
    asset: 'assets/illustrations/cold_water.svg',
    sections: [
      TipSection(
        'On en boit moins',
        'Très froide, l\'eau se boit difficilement en quantité : on s\'arrête '
            'après quelques gorgées. Une eau fraîche ou à température ambiante '
            'se boit plus facilement et plus souvent.',
      ),
      TipSection(
        'Dents, gorge et maux de tête',
        'L\'eau glacée peut réveiller la douleur des dents sensibles, irriter '
            'une gorge fragile et provoquer chez certains un mal de tête '
            'brutal (« cerveau gelé ») ou une crise de migraine.',
      ),
      TipSection(
        'Après un gros effort',
        'Au contraire, après un effort intense sous la chaleur, une eau '
            'fraîche aide à faire baisser la température du corps. Bois-la '
            'par petites gorgées plutôt que d\'un trait.',
      ),
    ],
    keyPoints: [
      'Fraîche oui, glacée avec modération',
      'Dents sensibles ou migraines : évite les glaçons',
      'Toujours par petites gorgées',
    ],
  ),
  KidneyTip(
    title: 'Les bienfaits de l\'eau citronnée',
    text: 'Quelques gouttes de citron dans un verre d\'eau : c\'est frais, '
        'c\'est bon, et ça aide beaucoup de gens à boire plus. Voici ce '
        'qu\'elle apporte vraiment.',
    short: 'Un filet de citron rend l\'eau plus facile à boire.',
    asset: 'assets/illustrations/lemon_water.svg',
    sections: [
      TipSection(
        'On boit plus volontiers',
        'Le goût du citron rend l\'eau plus agréable, sans sucre ni calories. '
            'Pour ceux qui « n\'ont pas envie » d\'eau, c\'est une excellente '
            'astuce.',
      ),
      TipSection(
        'Un petit plus pour les reins',
        'Le citron contient du citrate, qui aide à empêcher certains calculs '
            'rénaux de se former. Il apporte aussi un peu de vitamine C.',
      ),
      TipSection(
        'Protège tes dents',
        'Le citron est acide et peut user l\'émail des dents. Bois-le plutôt '
            'avec une paille, rince-toi la bouche à l\'eau claire après, et '
            'attends 30 minutes avant de te brosser les dents. Si tu as des '
            'brûlures d\'estomac, vas-y doucement.',
      ),
    ],
    keyPoints: [
      'Le citron aide à boire plus, sans sucre',
      'Son citrate aide contre certains calculs',
      'Rince ta bouche après pour protéger tes dents',
    ],
  ),
];

/// La leçon citée par l'alerte du soir.
final healthyKidneysTip = kidneyTips[8];

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
