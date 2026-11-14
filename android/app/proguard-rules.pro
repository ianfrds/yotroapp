# Disable bytecode rewriting that can break JNI reflection & Flutter channels
-dontoptimize

# ML Kit Text Recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google_mlkit_text_recognition.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.dexterous.**

# Flutter Engine & Plugin Communication
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter's Play Store deferred-component implementation is bundled in the
# Android embedding, but a standalone APK does not ship the optional Play Core
# runtime. These references are unreachable when deferred components are not
# configured, so R8 may safely ignore their absent classes.
-dontwarn com.google.android.play.core.**

# JNI & Core Plugins
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.crazecoder.openfile.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.llfbandit.app_links.** { *; }


