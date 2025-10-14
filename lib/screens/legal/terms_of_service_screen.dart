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
             '本規約は、CIT App（以下「本アプリ」）の利用条件を定めるものです。\n'
             'ユーザーの皆さま（以下「ユーザー」）は、本規約に同意したうえで本アプリをご利用ください。',
           ),
           SizedBox(height: 24),


           Text('第1条（適用）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '本規約は、ユーザーと本アプリ運営者（以下「運営者」）との間の本アプリの利用に関わる一切の関係に適用されます。',
           ),
           SizedBox(height: 16),


           Text('第2条（利用資格）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '本アプリは、千葉工業大学の学生及び教職員を対象としたサービスです。利用には千葉工業大学発行のメールアドレスによる認証が必要です。',
           ),
           SizedBox(height: 16),


           Text('第3条（禁止事項）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             'ユーザーは、以下の行為をしてはなりません。',
             style: TextStyle(fontWeight: FontWeight.w500),
           ),
           SizedBox(height: 8),
           Text(
             '■ 法令違反・公序良俗違反\n'
             '・法令、条例、規則に違反する行為\n'
             '・公序良俗に反する行為\n'
             '・犯罪行為に関連する行為\n\n'
             '■ 不適切なコンテンツの投稿・共有\n'
             '・わいせつ、ポルノグラフィー、性的な内容\n'
             '・差別的、排他的、ヘイトスピーチに該当する内容\n'
             '・攻撃的、脅迫的、威嚇的な内容\n'
             '・他者を中傷、誹謗、侮辱する内容\n'
             '・暴力的、グロテスクな内容\n'
             '・薬物、危険物に関する不適切な内容\n\n'
             '■ 迷惑行為・嫌がらせ\n'
             '・スパム行為、宣伝・勧誘行為\n'
             '・ストーカー行為、つきまとい行為\n'
             '・他のユーザーへの嫌がらせ\n'
             '・同じ内容の大量投稿\n\n'
             '■ 技術的な不正行為\n'
             '・不正アクセス、システムへの攻撃\n'
             '・なりすまし、虚偽の情報による登録\n'
             '・本アプリの運営を妨害する行為\n'
             '・リバースエンジニアリング、解析行為\n\n'
             '■ その他\n'
             '・知的財産権を侵害する行為\n'
             '・個人情報を不正に取得・利用する行為\n'
             '・営利目的での利用（許可されたものを除く）\n'
             '・その他、運営者が不適切と判断する行為',
           ),
           SizedBox(height: 16),


           Text('第4条（コンテンツの管理）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '1. 運営者は、投稿されたコンテンツが本規約に違反すると判断した場合、事前の通知なくコンテンツを削除することができます。\n\n'
             '2. 運営者は、不適切なコンテンツの監視・管理のため、AI技術やその他の手法を用いることがあります。\n\n'
             '3. ユーザーは、不適切なコンテンツやユーザーを発見した場合、アプリ内の通報機能を利用して運営者に報告することができます。',
           ),
           SizedBox(height: 16),


           Text('第5条（アカウントの停止・削除）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '運営者は、ユーザーが以下に該当する場合、事前の通知なくアカウントの利用停止または削除を行うことができます。\n\n'
             '・本規約に違反した場合\n'
             '・虚偽の情報を提供した場合\n'
             '・長期間にわたり本アプリを利用しない場合\n'
             '・反社会的勢力に該当すると判明した場合\n'
             '・その他、運営者が不適切と判断した場合\n\n'
             'アカウント停止・削除後も、本規約の関連条項は効力を持続します。',
           ),
           SizedBox(height: 16),


           Text('第6条（通報・ブロック機能）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '1. 本アプリでは、ユーザーの安全で快適な利用環境を確保するため、通報機能及びブロック機能を提供しています。\n\n'
             '2. ユーザーは、不適切なコンテンツや迷惑行為を行うユーザーを通報することができます。\n\n'
             '3. ユーザーは、特定のユーザーをブロックすることで、そのユーザーからのコンテンツや連絡を遮断することができます。\n\n'
             '4. 通報された内容は運営者が確認し、必要に応じて適切な措置を講じます。',
           ),
           SizedBox(height: 16),


           Text('第7条（本アプリの提供の停止等）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '運営者は、以下の場合において、事前の通知なく本アプリの全部または一部の提供を停止または中断することがあります。\n\n'
             '・システムの保守、点検、更新を行う場合\n'
             '・地震、停電等の不可抗力により提供が困難になった場合\n'
             '・その他、運営者が停止または中断を必要と判断した場合',
           ),
           SizedBox(height: 16),


           Text('第8条（免責事項）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '1. 運営者は、本アプリの利用によりユーザーに生じた損害について、運営者に故意または重大な過失がある場合を除き、一切の責任を負いません。\n\n'
             '2. 運営者は、本アプリの完全性、正確性、確実性、有用性について保証しません。\n\n'
             '3. ユーザー間でのトラブルについて、運営者は一切の責任を負いません。',
           ),
           SizedBox(height: 16),


           Text('第9条（規約の変更）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '運営者は、必要と判断した場合、本規約を変更することができます。重要な変更については、本アプリ上で事前に告知します。変更後も本アプリを継続利用することで、変更に同意したものとみなします。',
           ),
           SizedBox(height: 16),


           Text('第10条（準拠法・管轄裁判所）', style: TextStyle(fontWeight: FontWeight.bold)),
           SizedBox(height: 8),
           Text(
             '本規約は日本法に準拠し、本規約に関する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。',
           ),
           SizedBox(height: 24),


           Text(
             '最終更新日：2025年9月',
             style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
           ),
         ],
       ),
     ),
   );
 }
}
