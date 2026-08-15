import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/repositories/onboarding_repository.dart';

/// Clôt la présentation, que l'utilisateur l'ait parcourue ou passée.
///
/// « Passer » vaut « vu » : on ne repropose pas une présentation que quelqu'un
/// a explicitement écartée.
final class CompleteOnboarding implements UseCase<void, NoParams> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) =>
      _repository.markOnboardingCompleted();
}
