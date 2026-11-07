import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/voice_transaction_item.dart';
import '../services/voice_transaction_parser_service.dart';
import '../widgets/ambient_top_glow.dart';
import '../widgets/circular_spectrum_visualizer.dart';
import '../widgets/voice_multi_item_summary_sheet.dart';

/// Full-page Voice Transaction Recording Screen.
/// Displays an immersive glowing fluid wave orb spectrum, real-time live caption subtitle,
/// and adaptive routing for single/multi-item transaction entries.
class VoiceRecordingScreen extends StatefulWidget {
  final void Function(VoiceTransactionItem singleItem) onSingleItem;
  final void Function(List<VoiceTransactionItem> multiItems) onBatchSave;

  const VoiceRecordingScreen({
    super.key,
    required this.onSingleItem,
    required this.onBatchSave,
  });

  /// Opens VoiceRecordingScreen as a full-page modal route.
  static Future<void> open({
    required BuildContext context,
    required void Function(VoiceTransactionItem singleItem) onSingleItem,
    required void Function(List<VoiceTransactionItem> multiItems) onBatchSave,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceRecordingScreen(
          onSingleItem: onSingleItem,
          onBatchSave: onBatchSave,
        ),
      ),
    );
  }

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  String _recognizedWords = '';
  VoiceParseResult? _parseResult;
  Timer? _speechTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initAndStartListening();
  }

  @override
  void dispose() {
    _speechTimeoutTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initAndStartListening() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
            _onSpeechCompleted();
          }
        },
        onError: (val) {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
      );

      if (_speechAvailable && mounted) {
        _startListening();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _isListening = false;
        });
      }
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() {
      _isListening = true;
      _soundLevel = 0.0;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedWords = result.recognizedWords;
            _parseResult = VoiceTransactionParserService.parse(_recognizedWords);
          });
          _speechTimeoutTimer?.cancel();
          if (result.finalResult) {
            _onSpeechCompleted();
          } else {
            _speechTimeoutTimer = Timer(const Duration(milliseconds: 1800), () {
              if (mounted && _isListening && _recognizedWords.isNotEmpty) {
                _stopListeningAndProcess();
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          final normalized = (level + 20) / 30.0;
          setState(() {
            _soundLevel = normalized.clamp(0.0, 1.0);
          });
        },
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  Future<void> _stopListeningAndProcess() async {
    _speechTimeoutTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
    _onSpeechCompleted();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListeningAndProcess();
    } else {
      _startListening();
    }
  }

  void _onSpeechCompleted() {
    if (!mounted || _recognizedWords.trim().isEmpty) return;
    final result = VoiceTransactionParserService.parse(_recognizedWords);
    if (!result.isValid) return;

    _routeParsedResult(result);
  }

  void _routeParsedResult(VoiceParseResult result) {
    if (!result.isValid) return;

    if (result.isSingleItem) {
      // 1 Item -> Directly pop full screen and fill into AddTransactionScreen
      Navigator.of(context).pop();
      widget.onSingleItem(result.items.first);
    } else {
      // Multi-Item (>1) -> Pop full screen and open VoiceMultiItemSummarySheet
      Navigator.of(context).pop();
      VoiceMultiItemSummarySheet.show(
        context: context,
        items: result.items,
        onRetryRecording: () {
          VoiceRecordingScreen.open(
            context: context,
            onSingleItem: widget.onSingleItem,
            onBatchSave: widget.onBatchSave,
          );
        },
        onSaveAll: (confirmedItems) {
          widget.onBatchSave(confirmedItems);
        },
      );
    }
  }

  void _simulateSpeech(String text) {
    setState(() {
      _recognizedWords = text;
      _parseResult = VoiceTransactionParserService.parse(text);
      _soundLevel = 0.85;
    });
    Timer(const Duration(milliseconds: 900), () {
      if (mounted && _parseResult != null && _parseResult!.isValid) {
        _routeParsedResult(_parseResult!);
      }
    });
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C131D) : const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          // Atmospheric top glow
          if (isDark) const AmbientTopGlow(height: 520),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      // Back / Close Button
                      IconButton(
                        key: const Key('btn_close_voice_screen'),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            size: 20,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),

                      // Title
                      Expanded(
                        child: Text(
                          'Perekam Transaksi Suara',
                          style: GoogleFonts.interTight(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // Status Pulse Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? const Color(0xFF0066FF).withOpacity(0.18)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isListening
                                ? const Color(0xFF38BDF8).withOpacity(0.4)
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? const Color(0xFF38BDF8) : const Color(0xFF8EA4BE),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isListening ? 'Mendengarkan' : 'Dijeda',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _isListening ? const Color(0xFF38BDF8) : const Color(0xFF8EA4BE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content (Scrollable for smaller screens)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Fluid Wave Orb Visualizer (Center Stage)
                        Center(
                          child: CircularSpectrumVisualizer(
                            isListening: _isListening,
                            soundLevel: _soundLevel,
                            onCenterTap: _toggleListening,
                            size: 260,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle / Transcription Box (Generous Full-Page Style)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131A26) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _recognizedWords.isNotEmpty
                                  ? _recognizedWords
                                  : 'Silakan sebutkan transaksi, contoh:\n"Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta"',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontStyle: _recognizedWords.isEmpty ? FontStyle.italic : FontStyle.normal,
                                color: _recognizedWords.isNotEmpty
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : (isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8)),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Detection Status Pill
                        if (_parseResult != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _parseResult!.isValid
                                  ? const Color(0xFF39D98A).withOpacity(0.12)
                                  : const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _parseResult!.isValid
                                    ? const Color(0xFF39D98A).withOpacity(0.3)
                                    : const Color(0xFFF59E0B).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _parseResult!.isValid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                  size: 16,
                                  color: _parseResult!.isValid ? const Color(0xFF39D98A) : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _parseResult!.isValid
                                        ? 'Terdeteksi ${_parseResult!.items.length} item • Total: ${_formatCurrency(_parseResult!.totalAmount)}'
                                        : (_parseResult!.validationError ?? 'Menunggu nominal...'),
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _parseResult!.isValid ? const Color(0xFF39D98A) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Web-only Simulator Chips
                        if (kIsWeb || !_speechAvailable) ...[
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Simulasi Suara Cepat (Web Preview):',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                key: const Key('chip_sim_multi_item'),
                                label: Text(
                                  '4 Item (Siomay, Tahu Tek, Keyboard, HP)',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF334155),
                                  ),
                                ),
                                backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                                ),
                                onPressed: () {
                                  _simulateSpeech('Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta');
                                },
                              ),
                              ActionChip(
                                key: const Key('chip_sim_single_item'),
                                label: Text(
                                  '1 Item (Kopi Kenangan 25rb)',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF334155),
                                  ),
                                ),
                                backgroundColor: isDark ? const Color(0xFF131A26) : Colors.white,
                                side: BorderSide(
                                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                                ),
                                onPressed: () {
                                  _simulateSpeech('Kopi kenangan 25 ribu');
                                },
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      // Toggle mic button
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: OutlinedButton(
                          key: const Key('btn_toggle_recording'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.18) : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          onPressed: _toggleListening,
                          child: Icon(
                            _isListening ? Icons.pause_rounded : Icons.mic_rounded,
                            size: 24,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Selesai & Tinjau Button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            key: const Key('btn_finish_voice_input'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                              foregroundColor: isDark ? const Color(0xFF0C131D) : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (_parseResult != null && _parseResult!.isValid)
                                ? () => _routeParsedResult(_parseResult!)
                                : null,
                            child: Text(
                              'Selesai & Tinjau',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

