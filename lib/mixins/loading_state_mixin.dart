import 'package:flutter/material.dart';

/// Mixin to handle common loading states and error handling
/// Use this to reduce duplicate loading/error code across widgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _error;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Current error message
  String? get error => _error;

  /// Set loading state and rebuild widget
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _error = null; // Clear error when starting new operation
      });
    }
  }

  /// Set error message and rebuild widget
  void setError(String? error) {
    if (mounted) {
      setState(() {
        _error = error;
        _isLoading = false; // Stop loading when error occurs
      });
    }
  }

  /// Clear both loading and error states
  void clearState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  /// Execute an async operation with automatic loading/error handling
  Future<R?> executeWithLoading<R>(
    Future<R> Function() operation, {
    String? errorPrefix,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      final errorMessage =
          errorPrefix != null ? '$errorPrefix: $e' : e.toString();
      setError(errorMessage);
      return null;
    }
  }

  /// Widget to display loading indicator
  Widget buildLoadingIndicator({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }

  /// Widget to display error message
  Widget buildErrorWidget({VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
