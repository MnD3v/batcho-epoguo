import 'dart:async';

import 'package:bois_et_vis/widgets/motion.dart';

/// Les animations en boucle empêcheraient `pumpAndSettle` de se terminer.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Motion.loops = false;
  await testMain();
}
