import 'content_consent_grant.dart';
import 'user_consent.dart';

class DataConsentsHistory {
  const DataConsentsHistory({
    required this.consents,
    required this.contentGrants,
  });

  final List<UserConsent> consents;
  final List<ContentConsentGrant> contentGrants;

  factory DataConsentsHistory.fromJson(Map<String, dynamic> json) {
    return DataConsentsHistory(
      consents: (json['consents'] as List<dynamic>)
          .map((e) => UserConsent.fromJson(e as Map<String, dynamic>))
          .toList(),
      contentGrants: (json['contentGrants'] as List<dynamic>)
          .map((e) => ContentConsentGrant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
