import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final GenerativeModel _model = GenerativeModel();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // GenKit modeli başlatma işlemleri
    _initializeGenKit();
  }

  Future<void> _initializeGenKit() async {
    try {
      // Gemini modelini yapılandırma
      await _model.initialize(
        apiKey: 'AIzaSyCNNEMn22wYnpx9vl65N5iX8aid2USuYcI', // Gemini API anahtarınızı buraya ekleyin
        modelName: 'gemini-2.0-flash', // Gemini model adı
      );

      // Hoş geldin mesajını ekleyin
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Merhaba! Ben Gemini tarafından desteklenen bir AI chatbotum. Size nasıl yardımcı olabilirim?",
            isUser: false,
          ),
        );
      });
    } catch (e) {
      // API bağlantı hatasını göster
      setState(() {
        _messages.add(
          ChatMessage(
            text: "API bağlantısında hata oluştu: ${e.toString()}. Lütfen API anahtarınızı kontrol edin.",
            isUser: false,
          ),
        );
      });

      // Debug konsoluna hata bilgisi yazdır
      print('Gemini API Hata: ${e.toString()}');
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    try {
      // GenKit API'sini kullanarak yanıt alın
      final response = await _model.generateText(
        prompt: userMessage,
        maxTokens: 500,
        temperature: 0.7,
      );

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "API hatası: ${e.toString()}. Lütfen internet bağlantınızı ve API anahtarınızı kontrol edin.",
            isUser: false,
          ),
        );
        _isLoading = false;
      });

      // Debug konsoluna hata bilgisi yazdır
      print('Mesaj gönderme hatası: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Chatbot'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -2),
                    blurRadius: 4.0,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Mesajınızı girin...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
              ),
            ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}


class GenerativeModel {
  String? apiKey;
  String? modelName;
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  Future<void> initialize({required String apiKey, required String modelName}) async {
    this.apiKey = apiKey;
    this.modelName = modelName;

    // API anahtarının geçerliliğini test et
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$modelName?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('API anahtarı doğrulanamadı. Durum kodu: ${response.statusCode}, Yanıt: ${response.body}');
      }

      print('Gemini API bağlantısı başarılı!');
    } catch (e) {
      print('Gemini API bağlantısı başarısız: $e');
      throw Exception('Gemini API ile bağlantı kurulamadı: $e');
    }
  }

  Future<String> generateText({
    required String prompt,
    int maxTokens = 100,
    double temperature = 0.5,
  }) async {
    try {
      final String endpoint = '$baseUrl/$modelName:generateContent?key=$apiKey';

      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
          'topP': 0.95,
          'topK': 40,
        }
      };

      print('Gemini API isteği gönderiliyor: $endpoint');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Gemini API durum kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Gemini API yanıtı: ${response.body}');

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty &&
            data['candidates'][0]['content']['parts'][0]['text'] != null) {

          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        } else {
          print('Yanıt yapısı beklenen formatta değil: ${response.body}');
          throw Exception('API yanıt formatı işlenemedi');
        }
      } else {
        print('API hata kodu: ${response.statusCode}');
        print('API hata mesajı: ${response.body}');
        throw Exception('API yanıtı başarısız: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('API isteği sırasında hata: $e');
      throw Exception('Metin oluşturma sırasında hata: $e');
    }
  }
}
