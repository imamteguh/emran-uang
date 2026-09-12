export '../../presentation/bloc/auth_user.dart';

import '../../presentation/bloc/auth_user.dart';

/// Re-export [AuthUser] as domain entity [AuthUserEntity]
/// to maintain 100% backward compatibility with existing codebase.
typedef AuthUserEntity = AuthUser;
