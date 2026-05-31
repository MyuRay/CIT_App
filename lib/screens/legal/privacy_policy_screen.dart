import 'package:flutter/material.dart';

import 'legal_document_anchor.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({
    super.key,
    this.initialAnchor = LegalDocumentAnchor.none,
  });

  final LegalDocumentAnchor initialAnchor;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final _chibaChannelSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialAnchor == LegalDocumentAnchor.chibaChannel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToChibaChannelSection();
      });
    }
  }

  void _scrollToChibaChannelSection() {
    final targetContext = _chibaChannelSectionKey.currentContext;
    if (targetContext == null || !mounted) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プライバシーポリシー',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '本プライバシーポリシー（以下「本ポリシー」といいます）は、本アプリ「CIT App」（以下「本アプリ」といいます）におけるユーザー情報の取り扱いについて定めるものです。\n'
              '本アプリの運営者は「CIT App開発・運営チーム（代表：村井雅斗）」です。運営者は、関係法令および大学のルール等を遵守し、ユーザーのプライバシー保護に努めます。',
            ),
            const SizedBox(height: 24),

            const Text('1. 取得する情報', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本アプリは、ユーザー登録およびサービス提供にあたり、以下の情報を取得・保存する場合があります。\n'
              '\n'
              '（1）アカウント情報\n'
              '・メールアドレス\n'
              '・Firebase Authentication によって自動生成されるユーザーID（UID）\n'
              '・表示名（ニックネーム）\n'
              '\n'
              '（2）プロフィール・アプリ内コンテンツ\n'
              '・ユーザーがアプリ内で入力・投稿した情報（掲示板への投稿・コメント、学食レビュー等）\n'
              '\n'
              '（3）Cwitter（マイクロブログ機能）に関する情報\n'
              '・Cwitter ID、表示名、プロフィール画像、自己紹介、ハッシュタグ、SNS リンク\n'
              '・Cweet（投稿）、返信、いいね、recweet、フォロー・フォロワー関係\n'
              '・投稿に添付した画像、投票の選択内容\n'
              '・投稿・返信作成時に運営者が確認するため保存される登録メールアドレス（他のユーザーには公開されません）\n'
              '・通報・ブロックに関する情報\n'
              '\n',
            ),
            KeyedSubtree(
              key: _chibaChannelSectionKey,
              child: const Text(
                '（4）ちばちゃんねる（匿名掲示板機能）に関する情報\n'
                '・スレッドのタイトル、カテゴリ、レス（コメント）本文\n'
                '・レスに添付した画像\n'
                '・投稿者のユーザー ID および登録メールアドレス（画面上は匿名表示されますが、不正利用調査・通報対応等のため内部で保持する場合があります）\n'
                '・通報に関する情報\n',
              ),
            ),
            const Text(
              '\n'
              '（5）利用状況・端末情報\n'
              '・ログイン日時、利用履歴\n'
              '・端末のOS種別、端末モデル等の技術情報\n'
              '・アプリの動作ログ（エラー情報等）\n'
              '・プッシュ通知のための端末トークン（通知機能を利用する場合）\n'
              '\n'
              '（6）お問い合わせ情報\n'
              '・お問い合わせ時にご入力いただくメールアドレス、内容等',
            ),
            const SizedBox(height: 16),

            const Text('2. 情報の利用目的', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '取得した情報は、以下の目的の範囲内で利用します。\n'
              '・本アプリの提供および運営のため\n'
              '・ユーザー認証、アカウント管理のため\n'
              '・Cwitter およびちばちゃんねる等のコミュニティ機能の提供のため\n'
              '・投稿内容の表示、通知送信、フォロー・返信等の機能提供のため\n'
              '・通報・不正利用への対応、利用規約違反への対処のため\n'
              '・機能改善、新機能の検討、品質向上のため\n'
              '・不正利用の防止・セキュリティ確保のため\n'
              '・お問い合わせ対応のため\n'
              '・統計データの作成（個人を識別できない形での分析）のため',
            ),
            const SizedBox(height: 16),

            const Text('3. 利用する外部サービス', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本アプリでは、ユーザー情報の管理および認証のために、以下の外部サービスを利用しています。\n'
              '・Firebase Authentication\n'
              '・Cloud Firestore\n'
              '・Firebase Storage（画像等のアップロード）\n'
              '・Firebase Cloud Messaging（プッシュ通知）\n'
              '\n'
              'これらは Google LLC が提供するクラウドサービスであり、ユーザー情報はこれらのサービス上に保存される場合があります。'
              '各サービスのデータの取り扱いについては、各提供者のプライバシーポリシーもご確認ください。',
            ),
            const SizedBox(height: 16),

            const Text('4. パスワードの取り扱い', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本アプリでメールアドレスとパスワードによる登録・ログインを行う場合、そのパスワードは Firebase Authentication によって安全な方式でハッシュ化されて保存されます。\n'
              '運営者は、平文のパスワードを取得・保存・閲覧することはできません。\n'
              '\n'
              'また、MARINEアカウントや大学アドレス関連サービス等で利用しているパスワードと同一のパスワードを本アプリで使用しないよう、強く推奨いたします。',
            ),
            const SizedBox(height: 16),

            const Text('5. コミュニティ機能における公開情報', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. Cwitter では、ユーザーが設定した Cwitter ID、表示名、プロフィール情報、投稿・返信等が、本アプリを利用する認証済みユーザーに表示される場合があります。\n\n'
              '2. ちばちゃんねるでは、スレッドおよびレスの内容は匿名表示されますが、本アプリを利用する認証済みユーザーが閲覧できます。\n\n'
              '3. ユーザーは、自己の投稿内容が他のユーザーに表示されること、および運営者が本規約に基づき内容を確認・削除する場合があることを理解したうえで、各機能を利用するものとします。\n\n'
              '4. Cwitter のプロフィールに登録した外部 SNS 等へのリンクをタップした場合、リンク先は本アプリ外のサービスとなり、当該サービスのプライバシーポリシーが適用されます。',
            ),
            const SizedBox(height: 16),

            const Text('6. 個人情報の第三者提供', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '運営者は、以下の場合を除き、取得した個人情報を第三者（個人・団体を問わず）に提供しません。\n'
              '・ユーザー本人の同意がある場合\n'
              '・法令に基づき開示を求められた場合\n'
              '・人の生命、身体または財産の保護のために必要であり、本人の同意取得が困難な場合\n'
              '・大学等と連携して本アプリの安全な運営を行うために、個人を特定できない形で情報を共有する場合',
            ),
            const SizedBox(height: 16),

            const Text('7. 業務委託について', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '運営者は、本アプリの運営に必要な範囲で、システム運用等の業務を外部事業者に委託する場合があります。\n'
              'その際、委託先に対しては、適切な安全管理措置を求め、必要な監督を行います。',
            ),
            const SizedBox(height: 16),

            const Text('8. データの管理および削除', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '運営者は、取得した情報が漏えい、滅失、毀損等しないよう、合理的な安全管理措置を講じます。\n'
              '\n'
              'ユーザーがアカウント削除またはデータ削除を希望する場合は、アプリ内の問い合わせフォームまたは下記の問い合わせ窓口までご連絡ください。'
              '運営者は、Firebase Authentication 上のアカウント情報および Cloud Firestore 上の関連データ（Cwitter・ちばちゃんねるの投稿データを含む）を削除する等、適切な対応を行います。\n'
              '\n'
              'なお、法令順守やトラブル対応のために、必要な範囲で一定期間ログ等を保管する場合がありますが、その場合も目的達成後は適切な方法で削除または匿名化いたします。',
            ),
            const SizedBox(height: 16),

            const Text('9. お問い合わせ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本ポリシーおよび個人情報の取り扱いに関するご質問やご相談は、アプリ内のお問い合わせフォーム、'
              'または以下のメールアドレスまでご連絡ください。\n'
              '\n'
              '運営者名：CIT App開発・運営チーム（代表：村井雅斗）\n'
              'お問い合わせメールアドレス：masatomurai2004@gmail.com\n'
              '\n'
              'いただいたお問い合わせについては、可能な限り速やかに対応させていただきます。',
            ),
            const SizedBox(height: 16),

            const Text('10. プライバシーポリシーの変更', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本ポリシーの内容は、法令の改正や本アプリの機能追加・変更等に応じて、必要に応じて見直し・改定を行うことがあります。\n'
              '重要な変更を行う場合には、本アプリ上での掲示その他適切な方法によりお知らせいたします。',
            ),
            const SizedBox(height: 24),

            const Text(
              '最終更新日：2026年5月31日',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
