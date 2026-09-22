import 'package:flutter_test/flutter_test.dart';
import 'package:menifest_app/app/services/version_check_service.dart';

void main() {
  group('VersionCheckService.compareSemVer', () {
    test('Identical versions return 0', () {
      expect(VersionCheckService.compareSemVer('1.0.0', '1.0.0'), 0);
      expect(VersionCheckService.compareSemVer('1.2.3', '1.2.3'), 0);
    });

    test('Older version returns -1', () {
      expect(VersionCheckService.compareSemVer('1.0.0', '1.0.1'), -1);
      expect(VersionCheckService.compareSemVer('1.0.0', '1.1.0'), -1);
      expect(VersionCheckService.compareSemVer('1.0.0', '2.0.0'), -1);
      expect(VersionCheckService.compareSemVer('1.2.0', '1.10.0'), -1);
    });

    test('Newer version returns 1', () {
      expect(VersionCheckService.compareSemVer('1.0.1', '1.0.0'), 1);
      expect(VersionCheckService.compareSemVer('1.1.0', '1.0.0'), 1);
      expect(VersionCheckService.compareSemVer('2.0.0', '1.9.9'), 1);
      expect(VersionCheckService.compareSemVer('1.10.0', '1.2.0'), 1);
    });

    test('Handles build numbers and varying lengths', () {
      expect(VersionCheckService.compareSemVer('1.0.0+1', '1.0.0+2'), 0);
      expect(VersionCheckService.compareSemVer('1.0.0+5', '1.0.1+1'), -1);
      expect(VersionCheckService.compareSemVer('1.0', '1.0.0'), 0);
      expect(VersionCheckService.compareSemVer('1.0.1', '1.0'), 1);
    });
  });
}
