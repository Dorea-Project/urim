import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/account_repository_impl.dart';
import 'package:urim/domain/entities/account/church_membership.dart';
import 'package:urim/domain/entities/account/known_device.dart';
import 'package:urim/domain/entities/account/user_profile.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

/// Ce que l'écran de profil affiche.
final class ProfileState extends Equatable {
  const ProfileState({
    required this.profile,
    this.churches = const [],
    this.devices = const [],
  });

  final UserProfile profile;
  final List<ChurchMembership> churches;
  final List<KnownDevice> devices;

  ProfileState copyWith({
    UserProfile? profile,
    List<ChurchMembership>? churches,
    List<KnownDevice>? devices,
  }) =>
      ProfileState(
        profile: profile ?? this.profile,
        churches: churches ?? this.churches,
        devices: devices ?? this.devices,
      );

  @override
  List<Object?> get props => [profile, churches, devices];
}

/// Profil, églises et appareils.
///
/// Le numéro vient de la session, le nom du compte : deux sources, une seule
/// vue. Les recoller ici évite d'inventer une entité qui n'existerait que pour
/// les tenir ensemble.
final class ProfileViewModel extends AsyncNotifier<ProfileState> {
  @override
  Future<ProfileState> build() async {
    final session = await ref.watch(authSessionProvider.future);

    // L'écran n'est atteignable qu'une fois l'accès ouvert : sans session, ce
    // n'est pas un état vide, c'est une anomalie.
    if (session == null) {
      // Message technique, destiné aux journaux : l'écran produit le sien.
      throw const AuthFailure(
        message: 'Aucune session ouverte.',
        code: 'no_session',
      );
    }

    final repository = ref.watch(accountRepositoryProvider);

    final name = (await repository.displayName()).fold(
      onSuccess: (value) => value,
      onFailure: (failure) => throw failure,
    );
    final churches = (await repository.churches()).fold(
      onSuccess: (value) => value,
      onFailure: (failure) => throw failure,
    );
    final devices = (await repository.devices()).fold(
      onSuccess: (value) => value,
      onFailure: (failure) => throw failure,
    );

    return ProfileState(
      profile: UserProfile(phone: session.phone, displayName: name),
      churches: churches,
      devices: devices,
    );
  }

  /// Change le nom affiché. Renvoie la `Failure` en cas d'échec, `null` sinon.
  Future<Failure?> rename(String name) async {
    final current = state.value;
    if (current == null) return null;

    final result =
        await ref.read(accountRepositoryProvider).setDisplayName(name);

    return result.fold(
      onSuccess: (_) {
        state = AsyncData(
          current.copyWith(
            profile: current.profile.copyWith(displayName: name.trim()),
          ),
        );
        return null;
      },
      onFailure: (failure) => failure,
    );
  }

  /// Retire un appareil de la liste.
  Future<Failure?> forgetDevice(String deviceId) async {
    final current = state.value;
    if (current == null) return null;

    final repository = ref.read(accountRepositoryProvider);
    final failure = (await repository.forgetDevice(deviceId)).failureOrNull;

    if (failure != null) return failure;

    // On relit plutôt que de retirer l'élément de la liste locale : le jour où
    // un serveur répond, c'est lui qui dira ce qu'il reste.
    return (await repository.devices()).fold(
      onSuccess: (devices) {
        state = AsyncData(current.copyWith(devices: devices));
        return null;
      },
      onFailure: (failure) => failure,
    );
  }
}

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
