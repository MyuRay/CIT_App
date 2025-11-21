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
              '本プライバシーポリシー（以下「本ポリシー」といいます）は、本アプリ「CIT App」（以下「本アプリ」といいます）におけるユーザー情報の取り扱いについて定めるものです。\n'
              '本アプリの運営者は「CIT App開発・運営チーム（代表：村井雅斗）」です。運営者は、関係法令および大学のルール等を遵守し、ユーザーのプライバシー保護に努めます。',
            ),
            SizedBox(height: 24),

            // 1. 取得する情報
            Text('1. 取得する情報', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本アプリは、ユーザー登録およびサービス提供にあたり、以下の情報を取得・保存する場合があります。\n'
              '\n'
              '（1）アカウント情報\n'
              '・メールアドレス\n'
              '・Firebase Authentication によって自動生成されるユーザーID（UID）\n'
              '・表示名（ニックネーム）\n'
              '\n'
              '（2）プロフィール・アプリ内コンテンツ\n'
              '・ユーザーがアプリ内で入力・投稿した情報（レビュー、コメント等）\n'
              '\n'
              '（3）利用状況・端末情報\n'
              '・ログイン日時、利用履歴\n'
              '・端末のOS種別、端末モデル等の技術情報\n'
              '・アプリの動作ログ（エラー情報等）\n'
              '\n'
              '（4）お問い合わせ情報\n'
              '・お問い合わせ時にご入力いただくメールアドレス、内容等',
            ),
            SizedBox(height: 16),

            // 2. 利用目的
            Text('2. 情報の利用目的', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '取得した情報は、以下の目的の範囲内で利用します。\n'
              '・本アプリの提供および運営のため\n'
              '・ユーザー認証、アカウント管理のため\n'
              '・機能改善、新機能の検討、品質向上のため\n'
              '・不正利用の防止・セキュリティ確保のため\n'
              '・お問い合わせ対応のため\n'
              '・統計データの作成（個人を識別できない形での分析）のため',
            ),
            SizedBox(height: 16),

            // 3. 利用する外部サービス（Firebase）
            Text('3. 利用する外部サービス', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本アプリでは、ユーザー情報の管理および認証のために、以下の外部サービスを利用しています。\n'
              '・Firebase Authentication\n'
              '・Cloud Firestore\n'
              '\n'
              'これらは Google LLC が提供するクラウドサービスであり、ユーザー情報はこれらのサービス上に保存される場合があります。'
              '各サービスのデータの取り扱いについては、各提供者のプライバシーポリシーもご確認ください。',
            ),
            SizedBox(height: 16),

            // 4. パスワードの取り扱い
            Text('4. パスワードの取り扱い', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本アプリでメールアドレスとパスワードによる登録・ログインを行う場合、そのパスワードは Firebase Authentication によって安全な方式でハッシュ化されて保存されます。\n'
              '運営者は、平文のパスワードを取得・保存・閲覧することはできません。\n'
              '\n'
              'また、MARINEアカウントや大学アドレス関連サービス等で利用しているパスワードと同一のパスワードを本アプリで使用しないよう、強く推奨いたします。',
            ),
            SizedBox(height: 16),

            // 5. 個人情報の第三者提供
            Text('5. 個人情報の第三者提供', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '運営者は、以下の場合を除き、取得した個人情報を第三者（個人・団体を問わず）に提供しません。\n'
              '・ユーザー本人の同意がある場合\n'
              '・法令に基づき開示を求められた場合\n'
              '・人の生命、身体または財産の保護のために必要であり、本人の同意取得が困難な場合\n'
              '・大学等と連携して本アプリの安全な運営を行うために、個人を特定できない形で情報を共有する場合',
            ),
            SizedBox(height: 16),

            // 6. 業務委託
            Text('6. 業務委託について', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '運営者は、本アプリの運営に必要な範囲で、システム運用等の業務を外部事業者に委託する場合があります。\n'
              'その際、委託先に対しては、適切な安全管理措置を求め、必要な監督を行います。',
            ),
            SizedBox(height: 16),

            // 7. データの管理・削除
            Text('7. データの管理および削除', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '運営者は、取得した情報が漏えい、滅失、毀損等しないよう、合理的な安全管理措置を講じます。\n'
              '\n'
              'ユーザーがアカウント削除またはデータ削除を希望する場合は、アプリ内の問い合わせフォームまたは下記の問い合わせ窓口までご連絡ください。'
              '運営者は、Firebase Authentication 上のアカウント情報および Cloud Firestore 上の関連データを削除する等、適切な対応を行います。\n'
              '\n'
              'なお、法令順守やトラブル対応のために、必要な範囲で一定期間ログ等を保管する場合がありますが、その場合も目的達成後は適切な方法で削除または匿名化いたします。',
            ),
            SizedBox(height: 16),

            // 8. お問い合わせ
            Text('8. お問い合わせ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本ポリシーおよび個人情報の取り扱いに関するご質問やご相談は、アプリ内のお問い合わせフォーム、'
              'または以下のメールアドレスまでご連絡ください。\n'
              '\n'
              '運営者名：CIT App開発・運営チーム（代表：村井雅斗）\n'
              'お問い合わせメールアドレス：masatomurai2004@gmail.com\n'
              '\n'
              'いただいたお問い合わせについては、可能な限り速やかに対応させていただきます。',
            ),
            SizedBox(height: 16),

            // 9. プライバシーポリシーの変更
            Text('9. プライバシーポリシーの変更', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本ポリシーの内容は、法令の改正や本アプリの機能追加・変更等に応じて、必要に応じて見直し・改定を行うことがあります。\n'
              '重要な変更を行う場合には、本アプリ上での掲示その他適切な方法によりお知らせいたします。',
            ),
            SizedBox(height: 24),

            Text(
              '最終更新日：2025年11月21日',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
