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

    /// 📂 SAVE LOCALLY (ALWAYS)
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

    /// 🌍 OPTIONAL SERVER UPLOAD
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
      } catch (_) {
        // silent fail → local still saved
      }
    }

    setState(() => loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Book')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Pick PDF"),
            ),

            if (fileName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text("Selected: $fileName"),
              ),

            DropdownButton<String>(
              value: category,
              isExpanded: true,
              items: ["General", "Self Help", "Education", "Stories"]
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => category = v!),
            ),

            const SizedBox(height: 20),

            /// 🌍 COMMUNITY TOGGLE
            SwitchListTile(
              title: const Text("Share to community 🌍"),
              value: shareToCommunity,
              onChanged: (v) => setState(() => shareToCommunity = v),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: upload,
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}