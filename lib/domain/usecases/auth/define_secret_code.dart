import 'package:equatable/equatable.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/usecase/usecase.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';
import 'package:urim/domain/repositories/secret_code_repository.dart';

final class DefineSecretCodeParams extends Equatable {
  const DefineSecretCodeParams({
    required this.code,
    required this.confirmation,
  });

  final String code;
  final String confirmation;

  @override
  List<Object?> get props => [code, confirmation];
}

/// Définit le code secret de l'appareil.
final class DefineSecretCode implements UseCase<void, DefineSecretCodeParams> {
  const DefineSecretCode(this._repository);

  final SecretCodeRepository _repository;

  @override
  Future<Result<void>> call(DefineSecretCodeParams params) async {
    if (!SecretCodePolicy.hasValidShape(params.code)) {
      return const Result.failed(
        ValidationFailure(
          message: 'Le code comporte '
              '${SecretCodePolicy.length} chiffres.',
          code: 'invalid_shape',
          fieldErrors: {'code': 'Code incomplet'},
        ),
      );
    }

    if (SecretCodePolicy.isTrivial(params.code)) {
      return const Result.failed(
        ValidationFailure(
          message: 'Évitez une suite ou un chiffre répété.',
          code: 'trivial_code',
          fieldErrors: {'code': 'Code trop simple'},
        ),
      );
    }

    if (params.code != params.confirmation) {
      return const Result.failed(
        ValidationFailure(
          message: 'Les deux saisies diffèrent.',
          code: 'confirmation_mismatch',
          fieldErrors: {'confirmation': 'Ne correspond pas'},
        ),
      );
    }

    return _repository.defineSecretCode(params.code);
  }
}
