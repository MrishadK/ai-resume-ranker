import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ResumeRankerScreen(),
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
    ),
  );
}

class ResumeRankerScreen extends StatefulWidget {
  @override
  _ResumeRankerScreenState createState() => _ResumeRankerScreenState();
}

class _ResumeRankerScreenState extends State<ResumeRankerScreen> {
  List<PlatformFile> _files = [];
  String _jobDescription = '';
  List<dynamic> _results = [];
  bool _loading = false;

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _files = result.files;
        _results = [];
      });
    }
  }

  Future<void> submit() async {
    if (_jobDescription.trim().isEmpty) {
      _showSnack("Please enter job description");
      return;
    }
    if (_files.isEmpty) {
      _showSnack("Please pick at least one resume PDF");
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
    });

    var uri = Uri.parse(
      'http://192.168.1.3:5000/rank',
    ); //change ip address to given ip from app.py
    var request = http.MultipartRequest('POST', uri);
    request.fields['job_description'] = _jobDescription;

    for (var file in _files) {
      request.files.add(
        await http.MultipartFile.fromPath('resumes', file.path!),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _results = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showSnack(
          "Server error: ${response.statusCode} - ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnack("Failed to connect to server: $e");
    }
  }

  Future<void> downloadPdfReport() async {
    _showProgressDialog(context, "Downloading PDF Report...");

    final encodedJobDesc = Uri.encodeComponent(_jobDescription);
    final url = Uri.parse(
      'http://192.168.1.3:5000/download-report?job_description=$encodedJobDesc', //change ip address to given ip from app.py
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 &&
          (response.headers['content-type']?.contains('pdf') ?? false)) {
        final dir = await getExternalStorageDirectory();
        final path = dir?.path ?? '/storage/emulated/0/Download/';
        final file = File('$path/resume_ranking_report.pdf');
        await file.writeAsBytes(response.bodyBytes);

        Navigator.pop(context); // Dismiss dialog
        _showSnack("Report saved at: ${file.path}");
        OpenFile.open(file.path);
      } else {
        Navigator.pop(context);
        String errorMsg = "Error downloading PDF.";
        try {
          final jsonRes = json.decode(response.body);
          errorMsg = jsonRes['error'] ?? errorMsg;
        } catch (_) {}
        _showSnack(errorMsg);
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnack("Network error: $e");
    }
  }

  void _showProgressDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 12),
                Text(text),
              ],
            ),
          ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget buildResultList() {
    if (_results.isEmpty) {
      return Center(
        child: Text(
          "Upload resumes and provide a job description to see results.",
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (_, i) {
        var item = _results[i];
        double score = (item['score'] as num).toDouble();
        String name = item['name'];
        String filename = item['filename'];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: Text((i + 1).toString()),
            ),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  filename,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 6),
                LinearProgressIndicator(
                  value: score / 10,
                  color: score >= 7 ? Colors.green : Colors.orange,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            trailing: Chip(
              label: Text("${score.toStringAsFixed(1)} / 10"),
              backgroundColor:
                  score >= 7 ? Colors.green[100] : Colors.orange[100],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI-Powered Resume Ranker"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Enter Job Description",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _jobDescription = val,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: pickFiles,
                  icon: Icon(Icons.upload_file),
                  label: Text("Upload Resumes"),
                ),
                Text("${_files.length} files selected"),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : submit,
              icon: Icon(Icons.auto_graph),
              label:
                  _loading
                      ? Row(
                        children: [
                          Text("Ranking..."),
                          SizedBox(width: 10),
                          CircularProgressIndicator(),
                        ],
                      )
                      : Text("Rank Resumes"),
            ),
            const SizedBox(height: 10),
            if (_results.isNotEmpty)
              ElevatedButton.icon(
                onPressed: downloadPdfReport,
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Download PDF Report"),
              ),
            const SizedBox(height: 10),
            Expanded(child: buildResultList()),
          ],
        ),
      ),
    );
  }
}
