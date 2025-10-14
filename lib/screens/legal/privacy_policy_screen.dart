import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'プライバシーポリシー',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '本ポリシーは、本アプリにおけるユーザー情報の取り扱いについて定めるものです。\n'
              '運営者は、適用される法令を遵守し、ユーザーのプライバシー保護に努めます。',
            ),
            SizedBox(height: 24),
            Text('1. 取得する情報', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本アプリは、以下の情報を取得する場合があります。\n'
              '・アカウント情報（表示名、メールアドレス等）\n'
              '・利用状況や端末情報（ログ、端末モデル等）\n'
              '・お問い合わせ内容や送信メッセージ',
            ),
            SizedBox(height: 16),
            Text('2. 利用目的', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '・本アプリの提供、運営、品質向上のため\n'
              '・不正行為の防止、セキュリティ維持のため\n'
              '・お問い合わせ対応のため',
            ),
            SizedBox(height: 16),
            Text('3. 第三者提供', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('法令に基づく場合を除き、本人の同意なく第三者に提供しません。'),
            SizedBox(height: 16),
            Text('4. 委託', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('運営者は、必要な範囲で業務を委託し、適切に監督します。'),
            SizedBox(height: 16),
            Text('5. 安全管理措置', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('取得した情報の漏えい等を防止するため、合理的な安全管理措置を講じます。'),
            SizedBox(height: 16),
            Text('6. お問い合わせ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('個人情報の取扱いに関するお問い合わせは、アプリ内の問い合わせフォームからご連絡ください。'),
            SizedBox(height: 24),
            Text(
              '最終更新日：2025年09月',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

