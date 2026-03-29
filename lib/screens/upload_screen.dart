import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../storage/book_storage.dart';
import '../services/api_config.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? file;
  String fileName = "";
  String category = "General";

  bool shareToCommunity = false;
  bool loading = false;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        file = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  Future<void> upload() async {
    if (file == null) return;

    setState(() => loading = true);

    final dir = await getApplicationDocumentsDirectory();
    final saved = await file!.copy('${dir.path}/$fileName');

    final book = Book(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: fileName.replaceAll('.pdf', ''),
      path: saved.path,
      category: category,
      isRemote: false,
    );

    await BookStorage.addBook(book);

    if (shareToCommunity && ApiConfig.baseUrl != null) {
      try {
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/upload'),
        );

        req.files.add(
          await http.MultipartFile.fromPath('pdf', file!.path),
        );

        req.fields['category'] = category;

        await req.send().timeout(const Duration(seconds: 10));
      } catch (_) {}
    }

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),

      appBar: AppBar(
        title: const Text('Upload Book'),
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// 📂 PICK FILE CARD
            GestureDetector(
              onTap: pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E30),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file,
                        size: 40, color: Colors.amber),
                    const SizedBox(height: 10),
                    Text(
                      file == null
                          ? "Tap to select PDF"
                          : "Change File",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Only PDF files supported",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📄 FILE PREVIEW
            if (fileName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.redAccent, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            /// 📚 CATEGORY DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141E30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  dropdownColor: const Color(0xFF141E30),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: ["General", "Self Help", "Education", "Stories"]
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🌍 COMMUNITY TOGGLE
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141E30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                title: const Text(
                  "Share to community 🌍",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Let others read your book",
                  style: TextStyle(color: Colors.grey),
                ),
                value: shareToCommunity,
                activeColor: Colors.amber,
                onChanged: (v) =>
                    setState(() => shareToCommunity = v),
              ),
            ),

            const SizedBox(height: 30),

            /// 🚀 UPLOAD BUTTON
            loading
                ? const CircularProgressIndicator(color: Colors.amber)
                : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: upload,
                child: const Text(
                  "Upload Book",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}