import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LanguageTranslatorView extends StatefulWidget {
  const LanguageTranslatorView({super.key});

  @override
  State<LanguageTranslatorView> createState() => _LanguageTranslatorViewState();
}

class _LanguageTranslatorViewState extends State<LanguageTranslatorView> {
  String? _translatedText;
  final _controller = TextEditingController();
  var _sourceLanguage = TranslateLanguage.english;
  var _targetLanguage = TranslateLanguage.spanish;
  late OnDeviceTranslator _onDeviceTranslator;

  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  // ignore: unused_field
  var _identifiedLanguage = '';
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage, targetLanguage: _targetLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Language Translator'),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: [
              const SizedBox(height: 30),
              Center(
                  child: Text('Enter Text (detected source: ${_sourceLanguage.name})')),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                          border: Border.all(
                        width: 2,
                      )),
                      child: TextField(
                        controller: _controller,
                        decoration:
                            const InputDecoration(border: InputBorder.none),
                        maxLines: null,
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            _identifyAndTranslate(text);
                          }
                        },
                      ),
                    )),
                    const SizedBox(width: 20),
                    _buildDropdown(false),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Center(
                  child: Text(
                      'Translated Text (target: ${_targetLanguage.name})')),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                          width: MediaQuery.of(context).size.width / 1.3,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              border: Border.all(
                            width: 2,
                          )),
                          child: _isLoading 
                              ? const Center(child: CircularProgressIndicator())
                              : Text(_translatedText ?? '')),
                    ),
                    const SizedBox(width: 20),
                    _buildDropdown(true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                    onPressed: () => _identifyAndTranslate(_controller.text),
                    child: const Text('Translate'))
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(bool isTarget) => DropdownButton<String>(
        value: (isTarget ? _targetLanguage : _sourceLanguage).bcpCode,
        icon: const Icon(Icons.arrow_downward),
        elevation: 16,
        style: const TextStyle(color: Colors.blue),
        underline: Container(
          height: 2,
          color: Colors.blue,
        ),
        onChanged: (String? code) {
          if (code != null) {
            final lang = _getTranslateLanguageFromTag(code);
            if (lang != null) {
              setState(() {
                if (isTarget) {
                  _targetLanguage = lang;
                } else {
                  _sourceLanguage = lang;
                  _onDeviceTranslator = OnDeviceTranslator(
                      sourceLanguage: _sourceLanguage,
                      targetLanguage: _targetLanguage);
                }
              });
            }
          }
        },
        items: TranslateLanguage.values.map<DropdownMenuItem<String>>((lang) {
          return DropdownMenuItem<String>(
            value: lang.bcpCode,
            child: Text(lang.name),
          );
        }).toList(),
      );

  Future<void> _identifyAndTranslate(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true; 
    });
    
    String identifiedLanguage;
    try {
      identifiedLanguage = await _languageIdentifier.identifyLanguage(text);
    } on PlatformException catch (pe) {
      if (pe.code == _languageIdentifier.undeterminedLanguageCode) {
        identifiedLanguage = 'error: no language identified!';
      } else {
        identifiedLanguage = 'error: ${pe.code}: ${pe.message}';
      }
    } catch (e) {
      identifiedLanguage = 'error: ${e.toString()}';
    }

    if (identifiedLanguage.startsWith('error')) {
      setState(() {
        _identifiedLanguage = identifiedLanguage;
        _isLoading = false; // Set loading to false on error
      });
      return;
    }

    final sourceLang = _getTranslateLanguageFromTag(identifiedLanguage);
    if (sourceLang == null) {
      setState(() {
        _identifiedLanguage = 'error: unsupported language identified!';
        _isLoading = false; 
      });
      return;
    }

    _sourceLanguage = sourceLang;
    _onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: _sourceLanguage, targetLanguage: _targetLanguage);

    final translatedText = await _onDeviceTranslator.translateText(_controller.text);
    
    setState(() {
      _translatedText = translatedText;
      _isLoading = false; 
    });
  }

  TranslateLanguage? _getTranslateLanguageFromTag(String tag) {
    for (var lang in TranslateLanguage.values) {
      if (lang.bcpCode == tag) {
        return lang;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _onDeviceTranslator.close();
    _languageIdentifier.close();
    super.dispose();
  }
}
