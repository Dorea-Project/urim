import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/repositories/onboarding_repository.dart';

/// L'utilisateur a-t-il déjà vu la présentation ?
///
/// Consulté par la redirection du routeur à chaque démarrage.
final class HasCompletedOnboarding implements UseCase<bool, NoParams> {
  const HasCompletedOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Result<bool>> call(NoParams params) =>
      _repository.hasCompletedOnboarding();
}
