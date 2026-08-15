import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/id/id_generator.dart';

/// Fabrique d'identifiants de l'application. Les tests la remplacent par une
/// fabrique déterministe.
final idGeneratorProvider = Provider<IdGenerator>((ref) => LocalIdGenerator());
