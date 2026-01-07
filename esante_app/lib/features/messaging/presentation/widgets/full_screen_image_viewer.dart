import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full screen image viewer with swipe to dismiss (like Messenger)
class FullScreenImageViewer extends StatefulWidget {
  final String? imageUrl;
  final String? localPath;
  final String? heroTag;
  final String? senderName;
  final DateTime? sentAt;

  const FullScreenImageViewer({
    super.key,
    this.imageUrl,
    this.localPath,
    this.heroTag,
    this.senderName,
    this.sentAt,
  });

  /// Show the image viewer with a smooth transition
  static void show(
    BuildContext context, {
    String? imageUrl,
    String? localPath,
    String? heroTag,
    String? senderName,
    DateTime? sentAt,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(
            imageUrl: imageUrl,
            localPath: localPath,
            heroTag: heroTag,
            senderName: senderName,
            sentAt: sentAt,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  Offset _dragOffset = Offset.zero;
  double _dragScale = 1.0;
  bool _isDragging = false;

  // For pinch to zoom
  double _scale = 1.0;
  double _previousScale = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Set status bar to light content for dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  @override
  void dispose() {
    _animationController.dispose();
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final backgroundOpacity = _isDragging 
        ? (1.0 - (_dragOffset.distance / 300)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(backgroundOpacity * 0.95),
      body: Stack(
        children: [
          // Image with gestures - use only scale gesture for both pan and zoom
          GestureDetector(
            onTap: _dismiss,
            onScaleStart: (details) {
              _previousScale = _scale;
              if (details.pointerCount == 1) {
                // Single finger - start drag
                setState(() {
                  _isDragging = true;
                });
              }
            },
            onScaleUpdate: (details) {
              setState(() {
                if (details.pointerCount == 1 && _scale <= 1.0) {
                  // Single finger pan (drag to dismiss) - only when not zoomed
                  _dragOffset += details.focalPointDelta;
                  final distance = _dragOffset.distance;
                  _dragScale = (1.0 - (distance / 500)).clamp(0.5, 1.0);
                } else {
                  // Two finger pinch to zoom
                  _scale = (_previousScale * details.scale).clamp(0.5, 4.0);
                }
              });
            },
            onScaleEnd: (details) {
              final distance = _dragOffset.distance;
              final velocity = details.velocity.pixelsPerSecond.distance;
              
              // Dismiss if dragged far enough or with enough velocity
              if (distance > 100 || velocity > 500) {
                _dismiss();
              } else {
                // Animate back to center
                setState(() {
                  _isDragging = false;
                  _dragOffset = Offset.zero;
                  _dragScale = 1.0;
                  if (_scale < 1.0) {
                    _scale = 1.0;
                  }
                });
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform.scale(
                    scale: _dragScale * _scale,
                    child: widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: _buildImage(),
                          )
                        : _buildImage(),
                  ),
                ),
              ),
            ),
          ),

          // Top bar with close button and info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isDragging ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: _dismiss,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.senderName != null)
                                Text(
                                  widget.senderName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (widget.sentAt != null)
                                Text(
                                  _formatTime(widget.sentAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Swipe indicator at the top
          if (!_isDragging)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.localPath != null) {
      return Image.file(
        File(widget.localPath!),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }

    return _buildErrorWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load image',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
