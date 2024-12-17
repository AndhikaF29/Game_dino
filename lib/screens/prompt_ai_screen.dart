import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PromptAIScreen extends StatefulWidget {
  const PromptAIScreen({Key? key}) : super(key: key);

  @override
  _PromptAIScreenState createState() => _PromptAIScreenState();
}

class _PromptAIScreenState extends State<PromptAIScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _aiResponse = '';
  bool _isLoading = false;

  // API Key Groq AI
  final String _apiKey =
      "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";

  Future<void> _fetchAIResponse(String prompt) async {
    // Existing implementation remains the same
    setState(() {
      _isLoading = true;
      _aiResponse = "Sedang memproses prompt...";
    });

    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiResponse = data['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          _aiResponse =
              "Gagal mendapatkan respons dari AI. Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _aiResponse = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Ai Dino Runner',
                  style: TextStyle(
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.blueGrey[800]),
                  onPressed: () {
                    _showInformationDialog();
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPromptSection(),
                  const SizedBox(height: 20),
                  _buildResponseSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Enter Your Prompt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Masukan Kata disini',
                hintStyle: TextStyle(color: Colors.blueGrey[300]),
                filled: true,
                fillColor: Colors.blueGrey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_inputController.text.isNotEmpty) {
                    _fetchAIResponse(_inputController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Generete',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'AI Response',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueGrey,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _aiResponse.isEmpty
                            ? 'Your AI response will appear here...'
                            : _aiResponse,
                        style: TextStyle(
                          fontSize: 16,
                          color: _aiResponse.isEmpty
                              ? Colors.blueGrey[400]
                              : Colors.blueGrey[800],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInformationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('About AI Prompt Assistant'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('This app allows you to interact with an AI assistant.'),
              SizedBox(height: 10),
              Text('Simply enter a prompt and get an intelligent response.'),
              SizedBox(height: 10),
              Text('Powered by Groq AI with Llama 3.3 model.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
