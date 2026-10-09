import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/audio/audio_service.dart';
import 'package:pos_application/core/services/beep_service.dart';

void main() {
  test('the beep plays through AudioService only while the setting is on', () {
    var on = true;
    final audio = RecordingAudioService();
    final beep = SettingBeepService(() => on, audio);
    beep.play();
    beep.play();
    expect(audio.beeps, 2);
    on = false;
    beep.play();
    expect(audio.beeps, 2);
    on = true;
    beep.play();
    expect(audio.beeps, 3);
  });
}
