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

# JNI & Core Plugins
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.crazecoder.openfile.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.llfbandit.app_links.** { *; }


