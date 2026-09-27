import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Reno lit à voix haute, pour ceux qui lisent peu. Voix française du
/// téléphone rendue aiguë et vive : une petite voix d'enfant de dessin animé.
class ReadAloud {
  ReadAloud._();

  static final instance = ReadAloud._();

  /// Voix aiguë (1 = normale, 2 = maximum).
  static const pitch = 1.7;

  /// Un peu plus vive que d'habitude, mais toujours claire.
  static const rate = 0.5;

  /// Voix françaises féminines d'iOS : plus proches d'un enfant une fois
  /// rendues aiguës.
  static const _preferredVoices = ['Amélie', 'Audrey', 'Marie', 'Aurélie'];

  FlutterTts? _tts;

  Future<FlutterTts> _ready() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    await tts.setLanguage('fr-FR');
    await tts.setSpeechRate(rate);
    await tts.setPitch(pitch);
    try {
      final voices = (await tts.getVoices as List?) ?? const [];
      for (final name in _preferredVoices) {
        final voice = voices.whereType<Map>().where(
              (v) =>
                  '${v['locale']}'.startsWith('fr') &&
                  '${v['name']}'.contains(name),
            );
        if (voice.isNotEmpty) {
          await tts.setVoice({
            'name': '${voice.first['name']}',
            'locale': '${voice.first['locale']}',
          });
          break;
        }
      }
    } catch (_) {
      // Pas de liste de voix : la voix française par défaut suffit.
    }
    return _tts = tts;
  }

  Future<void> speak(String text) async {
    try {
      final tts = await _ready();
      await tts.stop();
      await tts.speak(speakable(text));
    } catch (e) {
      debugPrint('Lecture à voix haute : $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

/// Sans emojis (la voix les épellerait) ; « 0,5 L » → « 0,5 litre ».
@visibleForTesting
String speakable(String text) => text
    .replaceAll(
      RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
        unicode: true,
      ),
      '',
    )
    .replaceAllMapped(RegExp(r'(\d+(?:,\d+)?) L\b'), (m) {
      // En français, « litre » ne prend un s qu'à partir de 2.
      final value = double.parse(m[1]!.replaceAll(',', '.'));
      return '${m[1]} litre${value >= 2 ? 's' : ''}';
    })
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
