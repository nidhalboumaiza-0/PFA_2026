import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/document_entity.dart';

/// Full-screen document preview for images and PDFs
class DocumentPreviewScreen extends StatefulWidget {
  final AppointmentDocumentEntity document;

  const DocumentPreviewScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _isLoading = true;
  String? _localPdfPath;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.document.isPdf && !_isLocalFile) {
      _downloadPdf();
    } else {
      _isLoading = false;
    }
  }

  bool get _isLocalFile => widget.document.url.startsWith('file://');

  String get _localPath =>
      widget.document.url.replaceFirst('file://', '');

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.document.url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = widget.document.name.endsWith('.pdf')
            ? widget.document.name
            : '${widget.document.name}.pdf';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to download PDF (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error downloading PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _shareDocument,
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: _openInExternalApp,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in app',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading document...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: AppColors.error,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.document.isImage) {
      return _buildImageViewer();
    } else if (widget.document.isPdf) {
      return _buildPdfViewer();
    } else {
      return _buildUnsupportedFile();
    }
  }

  Widget _buildImageViewer() {
    final imageWidget = _isLocalFile
        ? Image.file(
            File(_localPath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildImageError(error.toString()),
          )
        : CachedNetworkImage(
            imageUrl: widget.document.url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) =>
                _buildImageError(error.toString()),
          );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(child: imageWidget),
    );
  }

  Widget _buildImageError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64.sp,
            color: Colors.white54,
          ),
          SizedBox(height: 16.h),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    final pdfPath = _isLocalFile ? _localPath : _localPdfPath;
    
    if (pdfPath == null) {
      return const Center(
        child: Text(
          'PDF file not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return PDFView(
      filePath: pdfPath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error on page $page: $error')),
        );
      },
    );
  }

  Widget _buildUnsupportedFile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 80.sp,
            color: Colors.white54,
          ),
          SizedBox(height: 24.h),
          Text(
            widget.document.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'This file type cannot be previewed',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: _openInExternalApp,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      if (_isLocalFile || _localPdfPath != null) {
        final path = _isLocalFile ? _localPath : _localPdfPath!;
        await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: widget.document.name));
      } else if (widget.document.isImage) {
        // Download image first, then share
        final response = await http.get(Uri.parse(widget.document.url));
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final ext = widget.document.extension.isNotEmpty
              ? widget.document.extension
              : 'jpg';
          final file = File('${tempDir.path}/${widget.document.name}.$ext');
          await file.writeAsBytes(response.bodyBytes);
          await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: widget.document.name));
        }
      } else {
        // Share URL
        await SharePlus.instance.share(ShareParams(uri: Uri.parse(widget.document.url), title: widget.document.name));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _openInExternalApp() async {
    try {
      final uri = Uri.parse(widget.document.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.document.url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
