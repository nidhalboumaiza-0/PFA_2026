import '../../domain/repositories/profile_repository.dart';

/// Use case to check if profile completion dialog should be shown
class CheckProfileCompletionUseCase {
  final ProfileRepository _repository;

  CheckProfileCompletionUseCase(this._repository);

  /// Returns true if the profile completion dialog should be shown
  Future<bool> call() async {
    return await _repository.needsProfileCompletion();
  }
}

/// Use case to mark that the user has seen the profile completion dialog
class MarkProfileCompletionShownUseCase {
  final ProfileRepository _repository;

  MarkProfileCompletionShownUseCase(this._repository);

  Future<void> call() async {
    await _repository.markProfileCompletionShown();
  }
}
