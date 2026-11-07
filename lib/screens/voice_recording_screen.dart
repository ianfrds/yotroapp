import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/voice_transaction_item.dart';
import '../services/voice_transaction_parser_service.dart';
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
  }) async {
    final result = await Navigator.of(context).push<VoiceParseResult>(
      MaterialPageRoute(
        builder: (_) => VoiceRecordingScreen(
          onSingleItem: onSingleItem,
          onBatchSave: onBatchSave,
        ),
      ),
    );

    if (result != null && result.isValid && context.mounted) {
      if (result.isSingleItem) {
        onSingleItem(result.items.first);
      } else {
        VoiceMultiItemSummarySheet.show(
          context: context,
          items: result.items,
          onRetryRecording: () {
            VoiceRecordingScreen.open(
              context: context,
              onSingleItem: onSingleItem,
              onBatchSave: onBatchSave,
            );
          },
          onSaveAll: (confirmedItems) {
            onBatchSave(confirmedItems);
          },
        );
      }
    }
  }

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  double _soundLevel = 0.0;
  double? _ambientSoundFloor;
  double? _peakSoundLevel;
  String _recognizedWords = '';
  VoiceParseResult? _parseResult;
  Timer? _speechTimeoutTimer;
  Timer? _silenceTimer;
  Timer? _spectrumPreviewTimer;
  bool _isSpectrumPreviewing = false;
  int _spectrumPreviewTick = 0;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initAndStartListening();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    _spectrumPreviewTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isListening) {
        _stopListeningDueToSilence();
      }
    });
  }

  Future<void> _stopListeningDueToSilence() async {
    _silenceTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0;
        });
      }
    }
  }

  Future<void> _initAndStartListening() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'listening') {
            setState(() => _isListening = true);
          } else if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
              _soundLevel = 0;
            });
          }
        },
        onError: (val) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _soundLevel = 0;
          });
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
      _ambientSoundFloor = null;
      _peakSoundLevel = null;
    });
    _startSilenceTimer();

    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _recognizedWords = result.recognizedWords;
            _parseResult =
                VoiceTransactionParserService.parse(_recognizedWords);
          });
          // Reset 5s silence countdown whenever speech is heard
          _startSilenceTimer();
        },
        onSoundLevelChange: _handleSoundLevel,
        listenOptions: stt.SpeechListenOptions(
          localeId: 'id_ID',
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0;
        });
      }
    }
  }

  void _handleSoundLevel(double rawLevel) {
    if (!mounted || !rawLevel.isFinite || _isSpectrumPreviewing) return;

    if (_ambientSoundFloor == null || _peakSoundLevel == null) {
      _ambientSoundFloor = rawLevel;
      _peakSoundLevel = rawLevel + 6;
      if (_soundLevel != 0) setState(() => _soundLevel = 0);
      return;
    }

    var floor = _ambientSoundFloor!;
    var peak = _peakSoundLevel!;

    // The floor follows quieter samples quickly but rises very slowly, so
    // continuous speech is not mistaken for ambient noise.
    if (rawLevel < floor) {
      floor += (rawLevel - floor) * .24;
    } else if (rawLevel < floor + 2.5) {
      floor += (rawLevel - floor) * .025;
    } else {
      floor += (rawLevel - floor) * .004;
    }

    if (rawLevel > peak) {
      peak += (rawLevel - peak) * .58;
    } else {
      final minimumPeak = floor + 6;
      peak += (minimumPeak - peak) * .018;
      peak = math.max(peak, minimumPeak);
    }

    _ambientSoundFloor = floor;
    _peakSoundLevel = peak;

    final dynamicRange = math.max(6.0, peak - floor);
    final noiseMargin = math.max(.75, dynamicRange * .1);
    final rawSignal = rawLevel - floor - noiseMargin;
    final normalized =
        (rawSignal / math.max(1, dynamicRange - noiseMargin)).clamp(0.0, 1.0);
    final compressed = math.pow(normalized, .72).toDouble();
    final smoothing = compressed > _soundLevel ? .6 : .18;
    final nextLevel = _soundLevel + (compressed - _soundLevel) * smoothing;

    if ((nextLevel - _soundLevel).abs() > .004) {
      setState(() => _soundLevel = nextLevel < .025 ? 0 : nextLevel);
    }
  }

  Future<void> _stopListeningAndProcess() async {
    _silenceTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0;
        });
      }
    }
  }

  void _toggleListening() {
    if (_isSpectrumPreviewing) {
      _stopSpectrumPreview();
      return;
    }
    if (_isListening) {
      _stopListeningAndProcess();
    } else {
      _startListening();
    }
  }

  void _routeParsedResult(VoiceParseResult result) {
    if (!result.isValid || _hasNavigated) return;
    _hasNavigated = true;
    _silenceTimer?.cancel();
    _speechTimeoutTimer?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    Navigator.of(context).pop(result);
  }

  void _simulateSpeech(String text) {
    if (_isSpectrumPreviewing) {
      _stopSpectrumPreview();
    }
    setState(() {
      _recognizedWords = text;
      _parseResult = VoiceTransactionParserService.parse(text);
      _soundLevel = 0.85;
      _isListening = false;
    });
    Timer(const Duration(milliseconds: 900), () {
      if (mounted && _parseResult != null && _parseResult!.isValid && !_hasNavigated) {
        _routeParsedResult(_parseResult!);
      }
    });
  }

  void _toggleSpectrumPreview() {
    if (!kIsWeb) return;
    if (_isSpectrumPreviewing) {
      _stopSpectrumPreview();
    } else {
      _startSpectrumPreview();
    }
  }

  void _startSpectrumPreview() {
    _spectrumPreviewTimer?.cancel();
    _spectrumPreviewTick = 0;
    setState(() {
      _isSpectrumPreviewing = true;
      _soundLevel = 0;
    });

    _spectrumPreviewTimer = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) {
        if (!mounted || !_isSpectrumPreviewing) return;
        _spectrumPreviewTick++;
        final cycleMs = (_spectrumPreviewTick * 70) % 4000;
        final phase = cycleMs / 4000;
        var previewEnergy = 0.0;

        // Each cycle deliberately demonstrates both states: a silent ring,
        // then a voice-like attack with layered amplitude fluctuations.
        if (phase >= .2 && phase <= .86) {
          final activePhase = (phase - .2) / .66;
          final envelope = math.min(
            1.0,
            math.min(activePhase * 7, (1 - activePhase) * 7),
          );
          final carrier = .58 +
              math.sin(_spectrumPreviewTick * .46) * .23 +
              math.sin(_spectrumPreviewTick * .17) * .12;
          previewEnergy = (carrier * envelope).clamp(0.0, 1.0);
        }

        setState(() => _soundLevel = previewEnergy);
      },
    );
  }

  void _stopSpectrumPreview() {
    _spectrumPreviewTimer?.cancel();
    _spectrumPreviewTimer = null;
    if (!mounted) return;
    setState(() {
      _isSpectrumPreviewing = false;
      _soundLevel = 0;
      _ambientSoundFloor = null;
      _peakSoundLevel = null;
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
    final pageColor =
        isDark ? const Color(0xFF09101C) : const Color(0xFFF4F5F7);
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText =
        isDark ? const Color(0xFF91A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: pageColor,
      body: Stack(
        children: [
          if (isDark)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, 1.25),
                      radius: 1.25,
                      colors: [
                        Color(0xFF034A8C),
                        Color(0xFF02386B),
                        Color(0xFF04213F),
                        Color(0x6606172C),
                        Color(0x0009101C),
                      ],
                      stops: [0.0, 0.28, 0.52, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox.square(
                    dimension: 42,
                    child: IconButton(
                      key: const Key('btn_close_voice_screen'),
                      tooltip: 'Tutup perekam suara',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF121620)
                            : const Color(0xFFE8EDF3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0x14FFFFFF)
                                : const Color(0xFFD7E0EA),
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: primaryText,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Text(
                    'Input Suara',
                    style: GoogleFonts.interTight(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularSpectrumVisualizer(
                            isListening: _isListening || _isSpectrumPreviewing,
                            soundLevel: _soundLevel,
                            onCenterTap: _isSpectrumPreviewing
                                ? _toggleSpectrumPreview
                                : _toggleListening,
                            size: 290,
                          ),
                          Semantics(
                            button: true,
                            label: (_isListening || _isSpectrumPreviewing)
                                ? 'Jeda perekaman'
                                : 'Mulai merekam',
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: const Key('btn_toggle_recording'),
                                onTap: _isSpectrumPreviewing
                                    ? _toggleSpectrumPreview
                                    : _toggleListening,
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? ((_isListening ||
                                                _isSpectrumPreviewing)
                                            ? const Color(0xFF131A26)
                                            : const Color(0xFF0D131C))
                                        : ((_isListening ||
                                                _isSpectrumPreviewing)
                                            ? Colors.white
                                            : const Color(0xFFF1F5F9)),
                                    border: Border.all(
                                      color: isDark
                                          ? ((_isListening ||
                                                  _isSpectrumPreviewing)
                                              ? const Color(0x33FFFFFF)
                                              : const Color(0x1FFFFFFF))
                                          : ((_isListening ||
                                                  _isSpectrumPreviewing)
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFFCBD5E1)),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? const Color(0x40000000)
                                            : const Color(0x0F000000),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      (_isListening || _isSpectrumPreviewing)
                                          ? Icons.pause_rounded
                                          : Icons.mic_rounded,
                                      size: 24,
                                      color: isDark
                                          ? ((_isListening ||
                                                  _isSpectrumPreviewing)
                                              ? Colors.white
                                              : const Color(0xFF91A3B8))
                                          : ((_isListening ||
                                                  _isSpectrumPreviewing)
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_recognizedWords.isEmpty)
                        Text(
                          'Contoh: "Kopi 25 ribu" atau "Siomay 13rb, tahu tek 100rb"',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: secondaryText.withOpacity(0.7),
                            height: 1.4,
                          ),
                        )
                      else ...[
                        Text(
                          '“$_recognizedWords”',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.interTight(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                            height: 1.3,
                          ),
                        ),
                        if (_parseResult != null) ...[
                          const SizedBox(height: 10),
                          _buildParseFeedback(
                            isDark: isDark,
                            secondaryText: secondaryText,
                          ),
                        ],
                      ],
                      if (kIsWeb || !_speechAvailable) ...[
                        const SizedBox(height: 28),
                        _buildSimulator(
                          isDark: isDark,
                          secondaryText: secondaryText,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const Key('btn_finish_voice_input'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF02539A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF121620)
                        : const Color(0xFFE2E8F0),
                    disabledForegroundColor: isDark
                        ? const Color(0xFF65788F)
                        : const Color(0xFF94A3B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _parseResult?.isValid == true
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
);
  }

  Widget _buildParseFeedback({
    required bool isDark,
    required Color secondaryText,
  }) {
    final isValid = _parseResult!.isValid;
    final accent = isValid ? const Color(0xFF39D98A) : const Color(0xFFF59E0B);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 15,
          color: accent,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isValid
                ? '${_parseResult!.items.length} item terdeteksi · ${_formatCurrency(_parseResult!.totalAmount)}'
                : (_parseResult!.validationError ?? 'Nominal belum terdeteksi'),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: isValid ? accent : secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulator({
    required bool isDark,
    required Color secondaryText,
  }) {
    final chipColor =
        isDark ? const Color(0xFF121620) : const Color(0xFFFFFFFF);
    final borderColor =
        isDark ? const Color(0x14FFFFFF) : const Color(0xFFD7E0EA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Contoh untuk pratinjau web',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondaryText.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (kIsWeb)
              ActionChip(
                key: const Key('btn_test_spectrum_preview'),
                avatar: Icon(
                  _isSpectrumPreviewing
                      ? Icons.stop_circle_outlined
                      : Icons.graphic_eq_rounded,
                  size: 16,
                ),
                label: Text(
                  _isSpectrumPreviewing
                      ? 'Hentikan tes spektrum'
                      : 'Tes gerak spektrum',
                ),
                labelStyle: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor:
                    _isSpectrumPreviewing ? const Color(0xFF0B2244) : chipColor,
                side: BorderSide(
                  color: _isSpectrumPreviewing
                      ? const Color(0x8055C7FF)
                      : borderColor,
                ),
                onPressed: _toggleSpectrumPreview,
              ),
            ActionChip(
              key: const Key('chip_sim_single_item'),
              avatar: const Icon(Icons.looks_one_outlined, size: 16),
              label: const Text('Kopi 25 ribu'),
              labelStyle: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: chipColor,
              side: BorderSide(color: borderColor),
              onPressed: () => _simulateSpeech('Kopi kenangan 25 ribu'),
            ),
            ActionChip(
              key: const Key('chip_sim_multi_item'),
              avatar: const Icon(Icons.format_list_numbered_rounded, size: 16),
              label: const Text('Empat transaksi'),
              labelStyle: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: chipColor,
              side: BorderSide(color: borderColor),
              onPressed: () => _simulateSpeech(
                'Siomay 13 ribu, tahu tek 100 ribu, keyboard 500 ribu, hp 1 juta',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
