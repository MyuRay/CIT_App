import 'package:flutter/material.dart';

import 'legal_document_anchor.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({
    super.key,
    this.initialAnchor = LegalDocumentAnchor.none,
  });

  final LegalDocumentAnchor initialAnchor;

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
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
        title: const Text('利用規約'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CIT App 利用規約',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '本規約は、CIT App（以下「本アプリ」といいます）の利用条件を定めるものです。\n'
              '本アプリは「CIT App開発・運営チーム（代表：村井雅斗）」が学生主導で開発・運営しているものであり、千葉工業大学が公式に提供・運営するシステムではありません。\n'
              'ユーザーの皆さま（以下「ユーザー」といいます）は、本規約に同意したうえで本アプリをご利用ください。',
            ),
            const SizedBox(height: 24),

            const Text('第1条（適用）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 本規約は、ユーザーと本アプリの運営者である「CIT App開発・運営チーム（代表：村井雅斗）」（以下「運営者」といいます）との間の、本アプリの利用に関わる一切の関係に適用されます。\n'
              '2. 本アプリは学生主導で運営されるものであり、千葉工業大学は本アプリの運営主体ではなく、本アプリの内容・提供状況・ユーザー間トラブル等について直接の責任を負うものではありません。',
            ),
            const SizedBox(height: 16),

            const Text('第2条（利用資格）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 本アプリは、主として千葉工業大学の学生および教職員を対象としたサービスです。\n'
              '2. 一部の機能の利用には、千葉工業大学発行のメールアドレスによる認証や、運営者が定める方法によるアカウント登録が必要となる場合があります。\n'
              '3. 本アプリは大学公式システムではないため、大学が提供する正規の情報・サービスとの相違が生じる場合があります。重要な情報については、必ず大学公式の情報源をご確認ください。',
            ),
            const SizedBox(height: 16),

            const Text('第3条（禁止事項）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
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
            const SizedBox(height: 16),

            const Text('第3条の2（Cwitter の利用）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. Cwitter は、本アプリ内のマイクロブログ型コミュニティ機能です。千葉工業大学のメールアドレスによる認証および Cwitter ID の設定が必要です。\n\n'
              '2. ユーザーは、Cwitter 上で投稿・返信・いいね・recweet・フォロー等を行う際、表示名、Cwitter ID、プロフィール情報（自己紹介、ハッシュタグ、SNS リンク、プロフィール画像等）、投稿本文、画像、投票等のコンテンツを送信する場合があります。\n\n'
              '3. Cwitter ID は一度設定すると変更できません。表示名やプロフィール情報は、ユーザー自身が変更できます。\n\n'
              '4. ユーザーは、Cwitter 上の投稿内容について自己の責任において管理するものとし、他者の権利を侵害する内容、虚偽の情報、嫌がらせ、差別的表現、わいせつな内容、スパム、なりすまし、大学や第三者の信用を不当に害する内容等を投稿してはなりません。\n\n'
              '5. ユーザーは、初回投稿前等に表示される投稿ガイドラインおよび本規約を遵守するものとします。\n\n'
              '6. 運営者は、通報・ブロック機能、AI 等を用いた監視、その他運営上必要な方法により、Cwitter 上のコンテンツやアカウントに対し、削除・非表示・利用制限等の措置を講じることができます。\n\n'
              '7. Cwitter 上の他ユーザーとのトラブルについて、運営者は原則として関与・仲裁・損害賠償責任を負いません。ただし、本規約違反が認められる場合は、運営者が適切と判断する範囲で対応します。\n\n'
              '8. Cwitter から外部 SNS 等へのリンクを開く場合、リンク先は本アプリ外のサービスであり、リンク先サイトの利用条件・安全性について運営者は責任を負いません。',
            ),
            const SizedBox(height: 16),

            KeyedSubtree(
              key: _chibaChannelSectionKey,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第3条の3（ちばちゃんねるの利用）',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. ちばちゃんねるは、本アプリ内の匿名掲示板型コミュニティ機能です。千葉工業大学のメールアドレスによる認証が必要です。\n\n'
                    '2. スレッドおよびレスの表示上、投稿者名は「名無しさん」として匿名表示されます。ただし、運営者は不正利用の調査、通報対応、法令遵守等のため、投稿者のユーザー ID や登録メールアドレス等の内部情報を確認できる場合があります。\n\n'
                    '3. ユーザーは、匿名性を理由として、他者への誹謗中傷、嫌がらせ、差別的表現、個人情報の晒し（ドキシング）、虚偽情報の拡散、違法行為の助長等を行ってはなりません。\n\n'
                    '4. スレッドのタイトル、カテゴリ、レス本文、画像等の投稿内容について、ユーザーは自己の責任において管理するものとします。\n\n'
                    '5. 運営者は、一定期間レスがないスレッドを格納庫へ移動する等、サービス運営上必要な整理を行うことがあります。\n\n'
                    '6. 運営者は、通報機能その他運営上必要な方法により、ちばちゃんねる上のコンテンツやアカウントに対し、削除・非表示・利用制限等の措置を講じることができます。',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('第4条（コンテンツの管理）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 運営者は、投稿されたコンテンツが本規約に違反すると判断した場合、事前の通知なくコンテンツを削除することができます。\n\n'
              '2. 運営者は、不適切なコンテンツの監視・管理のため、AI技術やその他の手法を用いることがあります。\n\n'
              '3. ユーザーは、不適切なコンテンツやユーザーを発見した場合、アプリ内の通報機能等を利用して運営者に報告することができます。\n\n'
              '4. Cwitter およびちばちゃんねる上の投稿・返信・スレッド等も、本条の対象とします。',
            ),
            const SizedBox(height: 16),

            const Text('第5条（アカウントの停止・削除）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '運営者は、ユーザーが以下に該当する場合、事前の通知なくアカウントの利用停止または削除を行うことができます。\n\n'
              '・本規約またはプライバシーポリシーに違反した場合\n'
              '・虚偽の情報を提供した場合\n'
              '・長期間にわたり本アプリを利用しない場合\n'
              '・反社会的勢力に該当すると判明した場合\n'
              '・その他、運営者が不適切と判断した場合\n\n'
              'アカウント停止・削除後も、本規約の性質上存続すべき条項は効力を持続します。',
            ),
            const SizedBox(height: 16),

            const Text('第6条（通報・ブロック機能）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 本アプリでは、ユーザーの安全で快適な利用環境を確保するため、通報機能およびブロック機能を提供する場合があります。\n\n'
              '2. ユーザーは、不適切なコンテンツや迷惑行為を行うユーザーを通報することができます。\n\n'
              '3. ユーザーは、特定のユーザーをブロックすることで、そのユーザーからのコンテンツや連絡を遮断することができます（機能が提供されている場合に限ります）。Cwitter ではブロック機能を提供しています。\n\n'
              '4. 通報された内容は運営者が確認し、必要に応じて適切な措置を講じます。',
            ),
            const SizedBox(height: 16),

            const Text('第7条（個人情報の取り扱い）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 本アプリにおけるユーザーの個人情報の取り扱いについては、別途定める「プライバシーポリシー」に従います。\n'
              '2. ユーザーは、本アプリを利用する前にプライバシーポリシーを確認し、その内容に同意したうえで本アプリを利用するものとします。\n'
              '3. 運営者は、プライバシーポリシーに定める範囲内で、ユーザー情報を取得・利用し、適切な安全管理措置を講じます。',
            ),
            const SizedBox(height: 16),

            const Text('第8条（本アプリの提供の停止等）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '運営者は、以下の場合において、事前の通知なく本アプリの全部または一部の提供を停止または中断することがあります。\n\n'
              '・システムの保守、点検、更新を行う場合\n'
              '・地震、停電、火災、天災等の不可抗力により提供が困難になった場合\n'
              '・外部サービスの障害・停止等により提供が困難になった場合\n'
              '・その他、運営者が停止または中断を必要と判断した場合',
            ),
            const SizedBox(height: 16),

            const Text('第9条（免責事項）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 運営者は、本アプリの利用によりユーザーに生じた損害について、運営者に故意または重大な過失がある場合を除き、一切の責任を負いません。\n\n'
              '2. 運営者は、本アプリの完全性、正確性、確実性、有用性について保証しません。ユーザーは、自らの責任において本アプリを利用するものとします。\n\n'
              '3. ユーザー間またはユーザーと第三者との間で生じたトラブルについて、運営者は一切の責任を負いません。\n\n'
              '4. 本アプリが大学の公式情報と異なる内容を表示した場合であっても、大学公式の情報が優先されるものとし、運営者はその差異に起因して生じた損害について責任を負いません。',
            ),
            const SizedBox(height: 16),

            const Text('第10条（規約の変更）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '1. 運営者は、必要と判断した場合、本規約を変更することができます。\n'
              '2. 重要な変更については、本アプリ上での掲示その他の適切な方法により事前に告知します。\n'
              '3. 規約変更後にユーザーが本アプリを継続して利用した場合、ユーザーは変更後の規約に同意したものとみなします。',
            ),
            const SizedBox(height: 16),

            const Text('第11条（準拠法・管轄裁判所）', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '本規約は日本法に準拠し、本規約または本アプリの利用に関して生じた紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。',
            ),
            const SizedBox(height: 24),

            const Text(
              '最終更新日：2026年5月31日',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
