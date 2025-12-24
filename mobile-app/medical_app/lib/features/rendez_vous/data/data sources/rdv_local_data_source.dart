import 'package:dartz/dartz.dart';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/RendezVous.dart';

abstract class RendezVousLocalDataSource {
  /// Caches the list of rendezvous locally.
  Future<Unit> cacheRendezVous(List<RendezVousModel> rendezVous);

  /// Retrieves the cached list of rendezvous.
  Future<List<RendezVousModel>> getCachedRendezVous();

  /// Clears cached rendezvous data.
  Future<Unit> clearRendezVous();
}

class RendezVousLocalDataSourceImpl implements RendezVousLocalDataSource {
  final SharedPreferences sharedPreferences;

  RendezVousLocalDataSourceImpl({required this.sharedPreferences});

  static const String RENDEZ_VOUS_KEY = 'CACHED_RENDEZ_VOUS';

  @override
  Future<Unit> cacheRendezVous(List<RendezVousModel> rendezVous) async {
    final rendezVousJson = rendezVous.map((r) => r.toJson()).toList();
    await sharedPreferences.setString(
      RENDEZ_VOUS_KEY,
      jsonEncode(rendezVousJson),
    );
    return unit;
  }

  @override
  Future<List<RendezVousModel>> getCachedRendezVous() async {
    final rendezVousJson = sharedPreferences.getString(RENDEZ_VOUS_KEY);
    if (rendezVousJson != null) {
      try {
        final rendezVousList = jsonDecode(rendezVousJson) as List<dynamic>;
        return rendezVousList
            .map(
              (json) => RendezVousModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } catch (e) {
        throw EmptyCacheException(
          message: 'Failed to parse cached rendezvous data: $e',
        );
      }
    } else {
      throw EmptyCacheException(message: 'No cached rendezvous data found');
    }
  }

  @override
  Future<Unit> clearRendezVous() async {
    await sharedPreferences.remove(RENDEZ_VOUS_KEY);
    return unit;
  }
}
