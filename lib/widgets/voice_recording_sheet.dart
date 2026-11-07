import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/voice_transaction_item.dart';
import '../screens/voice_recording_screen.dart';
import '../services/voice_transaction_parser_service.dart';
import 'circular_spectrum_visualizer.dart';
import 'voice_multi_item_summary_sheet.dart';

/// Modal bottom sheet that listens to user voice speech, shows Circular Audio Spectrum,
/// renders real-time subtitle transcription, and routes to single-fill or multi-item review.
class VoiceRecordingSheet extends StatefulWidget {
  final void Function(VoiceTransactionItem singleItem) onSingleItem;
  final void Function(List<VoiceTransactionItem> multiItems) onBatchSave;

  const VoiceRecordingSheet({
    super.key,
    required this.onSingleItem,
    required this.onBatchSave,
  });

  static Future<void> show({
    required BuildContext context,
    required void Function(VoiceTransactionItem singleItem) onSingleItem,
    required void Function(List<VoiceTransactionItem> multiItems) onBatchSave,
  }) {
    return VoiceRecordingScreen.open(
      context: context,
      onSingleItem: onSingleItem,
      onBatchSave: onBatchSave,
    );
  }

  @override
  State<VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends State<VoiceRecordingSheet> {
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
          // Reset debounce timer for auto-process after pause
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
          // Level from STT is usually -100 to 10 dB or 0 to 10
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
      // 1 Item -> Directly fill into AddTransactionScreen and close
      Navigator.of(context).pop();
      widget.onSingleItem(result.items.first);
    } else {
      // Multi-Item (>1) -> Open VoiceMultiItemSummarySheet
      Navigator.of(context).pop();
      VoiceMultiItemSummarySheet.show(
        context: context,
        items: result.items,
        onRetryRecording: () {
          VoiceRecordingSheet.show(
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
      _soundLevel = 0.75;
    });
    // Brief animation delay then route
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          bottomInset > 0 ? bottomInset + 12 : (bottomPadding > 0 ? bottomPadding + 8 : 16),
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C131D) : const Color(0xFFF4F5F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.55 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle pill
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perekam Transaksi Suara',
                      style: GoogleFonts.interTight(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _isListening
                          ? 'Mendengarkan ucapan pengguna...'
                          : 'Ketuk tombol lingkaran untuk mulai berbicara',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Circular Equalizer Spectrum Visualizer
          Center(
            child: CircularSpectrumVisualizer(
              isListening: _isListening,
              soundLevel: _soundLevel,
              onCenterTap: _toggleListening,
              size: 160,
            ),
          ),
          const SizedBox(height: 12),

          // Listening Pulse Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isListening
                  ? const Color(0xFF0066FF).withOpacity(0.16)
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
                Flexible(
                  child: Text(
                    _isListening ? 'Mendengarkan...' : 'Dijeda',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isListening ? const Color(0xFF38BDF8) : const Color(0xFF8EA4BE),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Subtitle / Caption Box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 64, maxHeight: 90),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _recognizedWords.isNotEmpty
                    ? _recognizedWords
                    : 'Silakan sebutkan transaksi, contoh:\n"Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta"',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontStyle: _recognizedWords.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: _recognizedWords.isNotEmpty
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8)),
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Real-time Detection Status / Validation Indicator
          if (_parseResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    _parseResult!.isValid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: _parseResult!.isValid ? const Color(0xFF39D98A) : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _parseResult!.isValid
                          ? 'Terdeteksi ${_parseResult!.items.length} item • Total: ${_formatCurrency(_parseResult!.totalAmount)}'
                          : (_parseResult!.validationError ?? 'Menunggu nominal...'),
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _parseResult!.isValid ? const Color(0xFF39D98A) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Test Simulation Chips (Hanya di Web Runner / saat speech tidak tersedia di perangkat)
          if (kIsWeb || !_speechAvailable) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Simulasi Suara Cepat:',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: isDark ? const Color(0xFF627D98) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  key: const Key('chip_sim_multi_item'),
                  label: Text(
                    '4 Item (Siomay, Tahu Tek, Keyboard, HP)',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF334155),
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
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
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF8EA4BE) : const Color(0xFF334155),
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF131A26) : const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFCBD5E1),
                  ),
                  onPressed: () {
                    _simulateSpeech('Kopi kenangan 25 ribu');
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Action Button: Selesai & Tinjau (Manual trigger if needed)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('btn_finish_voice_input'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (_parseResult != null && _parseResult!.isValid)
                  ? () => _routeParsedResult(_parseResult!)
                  : null,
              child: Text(
                'Selesai & Tinjau Transaksi',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
