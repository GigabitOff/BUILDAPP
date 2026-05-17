import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoReportsScreen extends StatefulWidget {
  final int? objectId;
  final String? objectName;

  const PhotoReportsScreen({super.key, this.objectId, this.objectName});

  @override
  State<PhotoReportsScreen> createState() => _PhotoReportsScreenState();
}

class _PhotoReportsScreenState extends State<PhotoReportsScreen> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController commentController = TextEditingController();

  // Р‘РћР•Р’РћР™ API.
  // Р’РђР–РќРћ: СЃСЋРґР° СЃС‚Р°РІРёРј СЂРµР°Р»СЊРЅС‹Р№ IP/РґРѕРјРµРЅ СЃРµСЂРІРµСЂР°, Р° РЅРµ 10.0.2.2.
  // РџСЂРёРјРµСЂ:
  // static const String baseUrl = 'http://93.175.196.148:3036';
  static const String baseUrl = 'http://185.112.41.227:3036';

  File? selectedImage;

  bool isLoading = false;
  bool isUploading = false;

  bool get isObjectMode => widget.objectId != null;

  final List<Map<String, String>> reports = [];

  @override
  void initState() {
    super.initState();

    if (widget.objectId != null) {
      loadPhotoReports();
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> loadPhotoReports() async {
    if (widget.objectId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final token = await getToken();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/construction-objects/${widget.objectId}/photo-reports',
            ),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List items = data['data'] ?? [];

        setState(() {
          reports.clear();

          reports.addAll(
            items.map<Map<String, String>>((item) {
              final String comment = '${item['comment'] ?? ''}'.trim();

              return {
                'id': '${item['id'] ?? ''}',
                'title': comment.isEmpty ? 'Р¤РѕС‚Рѕ СЃ РѕР±СЉРµРєС‚Р°' : comment,
                'object': widget.objectName ?? 'РћР±СЉРµРєС‚',
                'date': '${item['created_at'] ?? ''}',
                'photoPath': '',
                'photoUrl': '${item['photo_url'] ?? ''}',
                'userName': '${item['user_name'] ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ'}',
              };
            }).toList(),
          );
        });
      } else {
        throw Exception(data['message'] ?? 'РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё С„РѕС‚РѕРѕС‚С‡С‘С‚РѕРІ');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ С„РѕС‚РѕРѕС‚С‡С‘С‚С‹: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (image == null) return;

      setState(() {
        selectedImage = File(image.path);
        commentController.clear();
      });

      if (!mounted) return;

      await showAddPhotoDialog();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('РћС€РёР±РєР° РІС‹Р±РѕСЂР° С„РѕС‚Рѕ: $e')));
    }
  }

  void showPhotoSourceSheet() {
    if (!isObjectMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('РЎРЅР°С‡Р°Р»Р° РІС‹Р±РµСЂРё РѕР±СЉРµРєС‚')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Р”РѕР±Р°РІРёС‚СЊ С„РѕС‚Рѕ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 16),
                _SourceButton(
                  icon: Icons.photo_camera_outlined,
                  title: 'РЎРґРµР»Р°С‚СЊ С„РѕС‚Рѕ',
                  subtitle: 'РћС‚РєСЂС‹С‚СЊ РєР°РјРµСЂСѓ С‚РµР»РµС„РѕРЅР°',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _SourceButton(
                  icon: Icons.photo_library_outlined,
                  title: 'Р’С‹Р±СЂР°С‚СЊ РёР· РіР°Р»РµСЂРµРё',
                  subtitle: 'Р”РѕР±Р°РІРёС‚СЊ СѓР¶Рµ РіРѕС‚РѕРІРѕРµ С„РѕС‚Рѕ',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showAddPhotoDialog() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'РќРѕРІС‹Р№ С„РѕС‚РѕРѕС‚С‡С‘С‚',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (selectedImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          selectedImage!,
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'РљРѕРјРјРµРЅС‚Р°СЂРёР№',
                        hintText: 'РќР°РїСЂРёРјРµСЂ: РјРѕРЅС‚Р°Р¶ РІС‹РїРѕР»РЅРµРЅ, Р·Р°РјРµС‡Р°РЅРёР№ РЅРµС‚',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isUploading
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);

                                    setState(() {
                                      selectedImage = null;
                                      commentController.clear();
                                    });
                                  },
                            child: const Text('РћС‚РјРµРЅР°'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                    uploadPhotoReport();
                                  },
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('РЎРѕС…СЂР°РЅРёС‚СЊ'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> uploadPhotoReport() async {
    if (widget.objectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('РќРµ РІС‹Р±СЂР°РЅ РѕР±СЉРµРєС‚')));
      return;
    }

    if (selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Р¤РѕС‚Рѕ РЅРµ РІС‹Р±СЂР°РЅРѕ')));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final token = await getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$baseUrl/api/construction-objects/${widget.objectId}/photo-reports',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['comment'] = commentController.text.trim();

      request.files.add(
        await http.MultipartFile.fromPath('photo', selectedImage!.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        setState(() {
          selectedImage = null;
          commentController.clear();
        });

        await loadPhotoReports();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Р¤РѕС‚РѕРѕС‚С‡С‘С‚ СЃРѕС…СЂР°РЅС‘РЅ')));
      } else {
        throw Exception(data['message'] ?? 'РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ С„РѕС‚Рѕ');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РќРµ СѓРґР°Р»РѕСЃСЊ СЃРѕС…СЂР°РЅРёС‚СЊ С„РѕС‚Рѕ: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> deletePhotoReport(String reportId) async {
    if (reportId.isEmpty) return;

    try {
      final token = await getToken();

      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/photo-reports/$reportId'),
            headers: {
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await loadPhotoReports();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Р¤РѕС‚РѕРѕС‚С‡С‘С‚ СѓРґР°Р»С‘РЅ')));
      } else {
        throw Exception(data['message'] ?? 'РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ С„РѕС‚РѕРѕС‚С‡С‘С‚Р°');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ С„РѕС‚Рѕ: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  String formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';

    try {
      final date = DateTime.parse(rawDate).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day.$month.$year $hour:$minute';
    } catch (_) {
      return rawDate;
    }
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                color: Color(0xFF1F6FEB),
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Р¤РѕС‚РѕРѕС‚С‡С‘С‚РѕРІ РїРѕРєР° РЅРµС‚',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'РќР°Р¶РјРё вЂњР”РѕР±Р°РІРёС‚СЊвЂќ, СЃРґРµР»Р°Р№ С„РѕС‚Рѕ РёР»Рё РІС‹Р±РµСЂРё РµРіРѕ РёР· РіР°Р»РµСЂРµРё.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isObjectMode ? 'Р¤РѕС‚РѕРѕС‚С‡С‘С‚С‹ РѕР±СЉРµРєС‚Р°' : 'Р¤РѕС‚РѕРѕС‚С‡С‘С‚С‹';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadPhotoReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'РћР±РЅРѕРІРёС‚СЊ',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : showPhotoSourceSheet,
        backgroundColor: const Color(0xFF1F6FEB),
        foregroundColor: Colors.white,
        icon: isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(isUploading ? 'РЎРѕС…СЂР°РЅСЏРµРј...' : 'Р”РѕР±Р°РІРёС‚СЊ'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? buildEmptyState()
          : RefreshIndicator(
              onRefresh: loadPhotoReports,
              child: ListView.separated(
                padding: const EdgeInsets.all(22),
                itemCount: reports.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final report = reports[index];

                  return _PhotoReportCard(
                    id: report['id'] ?? '',
                    title: report['title'] ?? '',
                    object: report['object'] ?? '',
                    date: formatDate(report['date'] ?? ''),
                    photoPath: report['photoPath'] ?? '',
                    photoUrl: report['photoUrl'] ?? '',
                    userName: report['userName'] ?? '',
                    baseUrl: baseUrl,
                    onDelete: deletePhotoReport,
                  );
                },
              ),
            ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF1F6FEB), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _PhotoReportCard extends StatelessWidget {
  final String id;
  final String title;
  final String object;
  final String date;
  final String photoPath;
  final String photoUrl;
  final String userName;
  final String baseUrl;
  final Future<void> Function(String reportId) onDelete;

  const _PhotoReportCard({
    required this.id,
    required this.title,
    required this.object,
    required this.date,
    required this.photoPath,
    required this.photoUrl,
    required this.userName,
    required this.baseUrl,
    required this.onDelete,
  });

  String getFullPhotoUrl() {
    if (photoUrl.isEmpty) return '';

    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    return '$baseUrl$photoUrl';
  }

  Widget buildPhotoPreview({
    required double width,
    required double height,
    required BoxFit fit,
  }) {
    final fullPhotoUrl = getFullPhotoUrl();

    if (photoPath.isNotEmpty) {
      return Image.file(
        File(photoPath),
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (fullPhotoUrl.isNotEmpty) {
      return Image.network(
        fullPhotoUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            color: Colors.white,
            child: const Text(
              'Р¤РѕС‚Рѕ РЅРµ Р·Р°РіСЂСѓР·РёР»РѕСЃСЊ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          );
        },
      );
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Colors.white,
      child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF1F6FEB)),
    );
  }

  void openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Р¤РѕС‚РѕРѕС‚С‡С‘С‚',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await onDelete(id);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'РЈРґР°Р»РёС‚СЊ',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: buildPhotoPreview(
                      width: double.infinity,
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? 'Р¤РѕС‚Рѕ СЃ РѕР±СЉРµРєС‚Р°' : title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          object,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (userName.isNotEmpty)
                          Text(
                            'РђРІС‚РѕСЂ: $userName',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        if (userName.isNotEmpty) const SizedBox(height: 6),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Р—Р°РєСЂС‹С‚СЊ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = photoPath.isNotEmpty || photoUrl.isNotEmpty;

    return InkWell(
      onTap: () => openDetails(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: buildPhotoPreview(
                  width: 66,
                  height: 66,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF1F6FEB),
                  size: 28,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Р¤РѕС‚Рѕ СЃ РѕР±СЉРµРєС‚Р°' : title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    object,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}



