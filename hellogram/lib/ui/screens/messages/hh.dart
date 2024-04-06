import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:hellogram/data/env/env.dart';
import 'package:hellogram/domain/blocs/chat/chat_bloc.dart';
import 'package:hellogram/domain/blocs/user/user_bloc.dart';
import 'package:hellogram/domain/models/response/response_list_messages.dart';
import 'package:hellogram/domain/services/chat_services.dart';
import 'package:hellogram/ui/screens/messages/Generative/BardAIcontroller.dart';
import 'package:hellogram/ui/screens/messages/widgets/chat_message.dart';
import 'package:hellogram/ui/themes/colors_frave.dart';
import 'package:hellogram/ui/widgets/widgets.dart';

class ChatMessagesPage extends StatefulWidget {
  final String uidUserTarget;
  final String usernameTarget;
  final String avatarTarget;

  const ChatMessagesPage({
    Key? key,
    required this.uidUserTarget,
    required this.usernameTarget,
    required this.avatarTarget,
  }) : super(key: key);

  @override
  State<ChatMessagesPage> createState() => _ChatMessagesPageState();
}

class _ChatMessagesPageState extends State<ChatMessagesPage>
    with TickerProviderStateMixin {
  late ChatBloc chatBloc;
  late TextEditingController _messageController;
  final _focusNode = FocusNode();
  String genai="";
  List<ChatMessage> chatMessage = [];

  @override
  void initState() {
    super.initState();

    chatBloc = BlocProvider.of<ChatBloc>(context);

    chatBloc.initSocketChat();
    _historyMessages();

    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.clear();
    _messageController.dispose();
    for (ChatMessage message in chatMessage) {
      message.animationController.dispose();
    }

    chatBloc.disconnectSocket();
    chatBloc.disconnectSocketMessagePersonal();
    super.dispose();
  }

  _historyMessages() async {
    final List<ListMessage> list =
        await chatServices.listMessagesByUser(widget.uidUserTarget);

    final history = list.map((m) {
      final decryptedMessage = _decrypt(m.message);
      return ChatMessage(
        uidUser: m.sourceUid,
        message: decryptedMessage,
        time: m.createdAt,
        animationController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        )..forward(),
      );
    }).toList();

    setState(() => chatMessage.insertAll(0, history));
  }

  _handleSubmit(String text) {
    _messageController.clear();
    _focusNode.requestFocus();
    final userBloc = BlocProvider.of<UserBloc>(context).state;

    if (userBloc.user != null) {
      final encryptedMessage = _encrypt(text);

      final chat = ChatMessage(
        uidUser: userBloc.user!.uid,
        message: text,
        animationController: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        ),
      );

      chatMessage.insert(0, chat);
      chat.animationController.forward();

      setState(() {});

      chatBloc.add(
        OnEmitMessageEvent(
          userBloc.user!.uid,
          widget.uidUserTarget,
          encryptedMessage,
        ),
      );
    }
  }

  String _encrypt(String plaintext) {
    // Caesar Cipher with a fixed shift value of 3
    StringBuffer encryptedText = StringBuffer();

    for (int i = 0; i < plaintext.length; i++) {
      int charCode = plaintext.codeUnitAt(i);
      // Uppercase letters
      if (charCode >= 65 && charCode <= 90) {
        encryptedText.write(String.fromCharCode((charCode - 65 + 3) % 26 + 65));
      }
      // Lowercase letters
      else if (charCode >= 97 && charCode <= 122) {
        encryptedText.write(String.fromCharCode((charCode - 97 + 3) % 26 + 97));
      }
      // Other characters remain unchanged
      else {
        encryptedText.write(plaintext[i]);
      }
    }

    return encryptedText.toString();
  }

  String _decrypt(String ciphertext) {
    // Caesar Cipher with a fixed shift value of 3
    StringBuffer decryptedText = StringBuffer();

    for (int i = 0; i < ciphertext.length; i++) {
      int charCode = ciphertext.codeUnitAt(i);
      // Uppercase letters
      if (charCode >= 65 && charCode <= 90) {
        decryptedText.write(String.fromCharCode((charCode - 65 - 3 + 26) % 26 + 65));
      }
      // Lowercase letters
      else if (charCode >= 97 && charCode <= 122) {
        decryptedText.write(String.fromCharCode((charCode - 97 - 3 + 26) % 26 + 97));
      }
      // Other characters remain unchanged
      else {
        decryptedText.write(ciphertext[i]);
      }
    }

    return decryptedText.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: widget.usernameTarget,
                  fontWeight: FontWeight.w500,
                  fontSize: 21,
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          splashRadius: 20,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
        ),
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              Environment.baseUrl + widget.avatarTarget,
            ),
          ),
          const SizedBox(width: 10.0)
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (_, state) {
                if (state.message != null) {
                  final decryptedMessage = _decrypt(state.message!);
                  final chatListen = ChatMessage(
                    uidUser: state.uidSource!,
                    message: decryptedMessage,
                    time: state.createdAt!,
                    animationController: AnimationController(
                      vsync: this,
                      duration: const Duration(milliseconds: 350),
                    ),
                  );

                  chatMessage.insert(0, chatListen);
                  chatListen.animationController.forward();
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: chatMessage.length,
                  itemBuilder: (_, i) => chatMessage[i],
                );
              },
            ),
          ),
          _textMessage(),
        ],
      ),
    );
  }

  Widget _textMessage() {
    final chatBloc = BlocProvider.of<ChatBloc>(context);
        BardAIController controller = Get.put(BardAIController());

    return Container(
      color: Color.fromARGB(60, 255, 255, 255),
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        children: [
          Flexible(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (_, state) => TextField(
                style: TextStyle(color: Colors.white),
                
                controller: _messageController, 
                                focusNode: _focusNode,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    chatBloc.add(OnIsWrittingEvent(true));
                  } else {
                    chatBloc.add(OnIsWrittingEvent(false));
                  }
                  
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  label:Text(genai),
                  hintText: 'Write a message',
                  hintStyle: GoogleFonts.roboto(fontSize: 17),
                ),
              ),
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (_, state) => TextButton(
              onLongPress:  () {
                           
                              _messageController.clear();
                              setState(() {
                                 genai =  _generateMessage(_messageController.text.trim()) as String;
                              });
                            
                          }, 
              onPressed: state.isWritting
                  ? () =>_handleSubmit(_messageController.text.trim())
                  : null,
              child: const TextCustom(
                text: 'Send',
                color: Color.fromARGB(255, 128, 0, 126),
              ),
            ),
          ),
        ],
      ),
    );
  }
}







Future<String?> _generateMessage(String inputMessage) async {
    final apiKey = 'AIzaSyCOw9YpGz1D66DlGw5iD8q3SFLrK9WOwKU'; // Replace with your API key
    final url =
        'https://generativelanguage.googleapis.com/v1beta2/models/text-bison-001:generateText?key=$apiKey';

    final requestBody = jsonEncode({
      'prompt': inputMessage,
      'maxTokens': 50, // Maximum number of tokens in the generated text
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['text'] as String?;
      } else {
        print('Failed to generate message: ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      print('Error generating message: $e');
      return null;
    }
  }



