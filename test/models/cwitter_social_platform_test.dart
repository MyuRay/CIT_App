import 'package:cit_app/models/community/cwitter_social_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const discord = CwitterSocialPlatform.discord;
  const id = '123456789012345678';
  const profile = 'https://discord.com/users/$id';

  test('numeric IDs and pasted profile URLs open the same account', () {
    for (final input in [
      id,
      '  $id  ',
      '@$id',
      profile,
      '$profile/',
      '$profile?utm_source=share#profile',
      'discord.com/users/$id',
      'http://discordapp.com/users/$id',
      'https://www.discord.com/users/$id',
    ]) {
      expect(discord.resolveLaunchUrl(input), profile, reason: input);
    }
  });

  test('legacy invitation links still open Discord', () {
    for (final input in [
      'discord.gg/test-code',
      'https://discord.gg/test-code',
      'https://discordapp.com/invite/test-code',
      'https://discord.com/invite/test-code/',
    ]) {
      expect(
        discord.resolveLaunchUrl(input),
        'https://discord.com/invite/test-code',
        reason: input,
      );
    }
  });

  test('usernames and malformed profile IDs cannot become profile links', () {
    for (final input in [
      '',
      'student',
      '@student',
      'student#1234',
      '1234',
      '000000000000000000',
      '123456789012345678901',
      'https://discord.com/users/student',
      'https://discord.com/users/$id/extra',
    ]) {
      expect(discord.resolveLaunchUrl(input), isNull, reason: input);
    }
  });

  test(
    'lookalike hosts and arbitrary destinations never bypass confirmation',
    () {
      for (final input in [
        'https://discord.com.evil.example/users/$id',
        'https://evil.example/discord.com/users/$id',
        'https://discord.com@evil.example/users/$id',
        'https://evil.example@discord.com/users/$id',
        'https://discord.com:444/users/$id',
        'https://discord.com/oauth2/authorize?client_id=$id',
        'https://discord.com/users/123 456789012345678',
        'javascript:alert(1)',
        'file:///discord.com/users/$id',
        'intent://discord.com/users/$id',
      ]) {
        expect(discord.resolveLaunchUrl(input), isNull, reason: input);
      }
    },
  );

  test('saving another social link preserves existing Discord usernames', () {
    expect(
      CwitterSocialPlatform.sanitizeLinks({
        'discord': 'student',
        'instagram': 'new_name',
      }),
      {'discord': 'student', 'instagram': 'new_name'},
    );
    expect(CwitterSocialPlatform.parseLinks({'discord': 'student'}), {
      'discord': 'student',
    });
  });

  test('other platforms retain username and URL support', () {
    expect(
      CwitterSocialPlatform.instagram.resolveLaunchUrl('@student'),
      'https://instagram.com/student',
    );
    expect(
      CwitterSocialPlatform.x.resolveLaunchUrl('student'),
      'https://x.com/student',
    );
    expect(
      CwitterSocialPlatform.github.resolveLaunchUrl(
        'https://github.com/student',
      ),
      'https://github.com/student',
    );
  });
}
