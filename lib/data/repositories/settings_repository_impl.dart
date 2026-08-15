import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/settings_local_data_source.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';
import 'package:urim/domain/repositories/settings_repository.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Result<AppSettings>> load() async {
    try {
      return Result.success(await _local.read());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AppSettings>> save(AppSettings settings) async {
    try {
      await _local.write(settings);
      return Result.success(settings);
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(
    SharedPreferencesSettingsDataSource(ref.watch(sharedPreferencesProvider)),
  ),
);
