import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CIT App 利用規約',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '本規約は、CIT App（以下「本アプリ」といいます）の利用条件を定めるものです。\n'
              '本アプリは「CIT App開発・運営チーム（代表：村井雅斗）」が学生主導で開発・運営しているものであり、千葉工業大学が公式に提供・運営するシステムではありません。\n'
              'ユーザーの皆さま（以下「ユーザー」といいます）は、本規約に同意したうえで本アプリをご利用ください。',
            ),
            SizedBox(height: 24),

            // 第1条
            Text('第1条（適用）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 本規約は、ユーザーと本アプリの運営者である「CIT App開発・運営チーム（代表：村井雅斗）」（以下「運営者」といいます）との間の、本アプリの利用に関わる一切の関係に適用されます。\n'
              '2. 本アプリは学生主導で運営されるものであり、千葉工業大学は本アプリの運営主体ではなく、本アプリの内容・提供状況・ユーザー間トラブル等について直接の責任を負うものではありません。',
            ),
            SizedBox(height: 16),

            // 第2条
            Text('第2条（利用資格）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 本アプリは、主として千葉工業大学の学生および教職員を対象としたサービスです。\n'
              '2. 一部の機能の利用には、千葉工業大学発行のメールアドレスによる認証や、運営者が定める方法によるアカウント登録が必要となる場合があります。\n'
              '3. 本アプリは大学公式システムではないため、大学が提供する正規の情報・サービスとの相違が生じる場合があります。重要な情報については、必ず大学公式の情報源をご確認ください。',
            ),
            SizedBox(height: 16),

            // 第3条
            Text('第3条（禁止事項）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '■ 法令違反・公序良俗違反\n'
              '・法令、条例、規則に違反する行為\n'
              '・公序良俗に反する行為\n'
              '・犯罪行為に関連する行為\n\n'
              '■ 不適切なコンテンツの投稿・共有\n'
              '・わいせつ、ポルノグラフィー、過度に性的な内容\n'
              '・差別的、排他的、ヘイトスピーチに該当する内容\n'
              '・攻撃的、脅迫的、威嚇的な内容\n'
              '・他者を中傷、誹謗、侮辱する内容\n'
              '・暴力的、グロテスクな内容\n'
              '・違法薬物、危険物に関する不適切な内容\n\n'
              '■ 迷惑行為・嫌がらせ\n'
              '・スパム行為、過度な宣伝・勧誘行為\n'
              '・ストーカー行為、つきまとい行為\n'
              '・他のユーザーへの嫌がらせ\n'
              '・同じ内容の大量投稿\n\n'
              '■ 技術的な不正行為\n'
              '・不正アクセス、システムへの攻撃\n'
              '・なりすまし、虚偽の情報による登録\n'
              '・本アプリの運営を妨害する行為\n'
              '・リバースエンジニアリング、解析行為\n\n'
              '■ 個人情報・プライバシーの侵害\n'
              '・他者の個人情報を本人の同意なく収集・利用・公開する行為\n'
              '・本アプリを通じて取得した情報を不正な目的で利用する行為\n\n'
              '■ その他\n'
              '・知的財産権を侵害する行為\n'
              '・営利目的での利用（運営者が許可したものを除く）\n'
              '・その他、運営者が不適切と判断する行為',
            ),
            SizedBox(height: 16),

            // 第4条
            Text('第4条（コンテンツの管理）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 運営者は、投稿されたコンテンツが本規約に違反すると判断した場合、事前の通知なくコンテンツを削除することができます。\n\n'
              '2. 運営者は、不適切なコンテンツの監視・管理のため、AI技術やその他の手法を用いることがあります。\n\n'
              '3. ユーザーは、不適切なコンテンツやユーザーを発見した場合、アプリ内の通報機能等を利用して運営者に報告することができます。',
            ),
            SizedBox(height: 16),

            // 第5条
            Text('第5条（アカウントの停止・削除）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '運営者は、ユーザーが以下に該当する場合、事前の通知なくアカウントの利用停止または削除を行うことができます。\n\n'
              '・本規約またはプライバシーポリシーに違反した場合\n'
              '・虚偽の情報を提供した場合\n'
              '・長期間にわたり本アプリを利用しない場合\n'
              '・反社会的勢力に該当すると判明した場合\n'
              '・その他、運営者が不適切と判断した場合\n\n'
              'アカウント停止・削除後も、本規約の性質上存続すべき条項は効力を持続します。',
            ),
            SizedBox(height: 16),

            // 第6条
            Text('第6条（通報・ブロック機能）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 本アプリでは、ユーザーの安全で快適な利用環境を確保するため、通報機能およびブロック機能を提供する場合があります。\n\n'
              '2. ユーザーは、不適切なコンテンツや迷惑行為を行うユーザーを通報することができます。\n\n'
              '3. ユーザーは、特定のユーザーをブロックすることで、そのユーザーからのコンテンツや連絡を遮断することができます（機能が提供されている場合に限ります）。\n\n'
              '4. 通報された内容は運営者が確認し、必要に応じて適切な措置を講じます。',
            ),
            SizedBox(height: 16),

            // 第7条
            Text('第7条（個人情報の取り扱い）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 本アプリにおけるユーザーの個人情報の取り扱いについては、別途定める「プライバシーポリシー」に従います。\n'
              '2. ユーザーは、本アプリを利用する前にプライバシーポリシーを確認し、その内容に同意したうえで本アプリを利用するものとします。\n'
              '3. 運営者は、プライバシーポリシーに定める範囲内で、ユーザー情報を取得・利用し、適切な安全管理措置を講じます。',
            ),
            SizedBox(height: 16),

            // 第8条
            Text('第8条（本アプリの提供の停止等）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '運営者は、以下の場合において、事前の通知なく本アプリの全部または一部の提供を停止または中断することがあります。\n\n'
              '・システムの保守、点検、更新を行う場合\n'
              '・地震、停電、火災、天災等の不可抗力により提供が困難になった場合\n'
              '・外部サービスの障害・停止等により提供が困難になった場合\n'
              '・その他、運営者が停止または中断を必要と判断した場合',
            ),
            SizedBox(height: 16),

            // 第9条
            Text('第9条（免責事項）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 運営者は、本アプリの利用によりユーザーに生じた損害について、運営者に故意または重大な過失がある場合を除き、一切の責任を負いません。\n\n'
              '2. 運営者は、本アプリの完全性、正確性、確実性、有用性について保証しません。ユーザーは、自らの責任において本アプリを利用するものとします。\n\n'
              '3. ユーザー間またはユーザーと第三者との間で生じたトラブルについて、運営者は一切の責任を負いません。\n\n'
              '4. 本アプリが大学の公式情報と異なる内容を表示した場合であっても、大学公式の情報が優先されるものとし、運営者はその差異に起因して生じた損害について責任を負いません。',
            ),
            SizedBox(height: 16),

            // 第10条
            Text('第10条（規約の変更）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '1. 運営者は、必要と判断した場合、本規約を変更することができます。\n'
              '2. 重要な変更については、本アプリ上での掲示その他の適切な方法により事前に告知します。\n'
              '3. 規約変更後にユーザーが本アプリを継続して利用した場合、ユーザーは変更後の規約に同意したものとみなします。',
            ),
            SizedBox(height: 16),

            // 第11条
            Text('第11条（準拠法・管轄裁判所）', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              '本規約は日本法に準拠し、本規約または本アプリの利用に関して生じた紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。',
            ),
            SizedBox(height: 24),

            Text(
              '最終更新日：2025年11月21日',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
