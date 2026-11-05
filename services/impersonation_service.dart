import '../models/impersonation_session.dart';
import 'base_api_service.dart';

class ImpersonationService extends BaseApiService {
  Future<ImpersonationSession> impersonate({
    required int userId,
    required int userIdImpersonate,
  }) async {
    if (userId <= 0 || userIdImpersonate <= 0 || userId == userIdImpersonate) {
      throw ArgumentError('Select a different, valid user.');
    }

    final response = await index(
      '/profile/v1/auth/impersonate',
      config: {
        'refresh': true,
        'cache': false,
        'params': {'userId': userId, 'userIdImpersonate': userIdImpersonate},
      },
    );
    return ImpersonationSession.fromResponse(response, userIdImpersonate);
  }
}
