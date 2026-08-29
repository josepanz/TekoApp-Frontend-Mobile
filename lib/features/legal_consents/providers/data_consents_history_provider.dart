import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/data_consents_history.dart';
import 'legal_consents_repository_provider.dart';

final dataConsentsHistoryProvider =
    FutureProvider.autoDispose<DataConsentsHistory>((ref) async {
  return ref.watch(legalConsentsRepositoryProvider).fetchDataConsentsHistory();
});
