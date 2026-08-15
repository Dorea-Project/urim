import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/secret_code_local_data_source.dart';
import 'package:urim/domain/repositories/secret_code_repository.dart';

final class SecretCodeRepositoryImpl implements SecretCodeRepository {
  const SecretCodeRepositoryImpl(this._source);

  final SecretCodeLocalDataSource _source;

  @override
  Future<Result<bool>> hasSecretCode() => _guard(_source.isDefined);

  @override
  Future<Result<void>> defineSecretCode(String code) =>
      _guard(() => _source.define(code));

  @override
  Future<Result<bool>> verifySecretCode(String code) =>
      _guard(() => _source.verify(code));

  @override
  Future<Result<void>> clearSecretCode() => _guard(_source.clear);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }
}

final secretCodeRepositoryProvider = Provider<SecretCodeRepository>(
  (ref) => SecretCodeRepositoryImpl(
    SharedPreferencesSecretCodeDataSource(
      ref.watch(sharedPreferencesProvider),
    ),
  ),
);
