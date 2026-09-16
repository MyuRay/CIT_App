import 'package:cit_app/models/ads/in_app_ad_model.dart';
import 'package:cit_app/models/bulletin/bulletin_model.dart';

final sponsorTestNow = DateTime(2026, 9, 16, 12);

BulletinPost sponsorTestPost({
  String id = 'sponsor',
  String title = '学生限定・秋の応援キャンペーン',
  String name = '津田沼カフェ',
  bool sponsored = true,
  bool active = true,
  String approval = 'approved',
  DateTime? expiry,
  int views = 120,
}) => BulletinPost(
  id: id,
  title: title,
  description: '授業の合間にほっとひと息。学生証の提示でドリンクがお得になります。',
  imageUrl: '',
  category: BulletinCategories.coupon,
  createdAt: DateTime(2026, 9, 12),
  expiresAt: expiry,
  authorId: 'owner',
  authorName: 'CIT App運営',
  isActive: active,
  approvalStatus: approval,
  viewCount: views,
  allowComments: false,
  isSponsored: sponsored,
  sponsorName: sponsored ? name : '',
);

InAppAd sponsorTestAd({bool sponsored = true}) => InAppAd(
  id: 'ad',
  title: '学生限定・ドリンク100円引き',
  body: '勉強にも、おしゃべりにも。学生証を持ってお立ち寄りください。',
  ctaText: 'お店のキャンペーンを見る',
  placement: AdPlacement.homeTop,
  actionType: AdActionType.external,
  actionPayload: 'https://example.com',
  isActive: true,
  isSponsored: sponsored,
  sponsorName: sponsored ? '津田沼カフェ' : '',
);
