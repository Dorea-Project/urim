import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/onboarding_local_data_source.dart';
import 'package:urim/domain/repositories/onboarding_repository.dart';

final class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._local);

  final OnboardingLocalDataSource _local;

  @override
  Future<Result<bool>> hasCompletedOnboarding() async {
    try {
      return Result.success(await _local.hasCompleted());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markOnboardingCompleted() async {
    try {
      await _local.markCompleted();
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepositoryImpl(
    SharedPreferencesOnboardingDataSource(ref.watch(sharedPreferencesProvider)),
  ),
);
