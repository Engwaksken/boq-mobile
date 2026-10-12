# BOQ Works application ProGuard/R8 rules.

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses,EnclosingMethod

# Flutter embedding and generated plugin registrant (looked up reflectively).
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# The Flutter engine references Play Core for deferred components, which this
# app does not ship; without these R8 fails with "Missing class" errors.
-dontwarn com.google.android.play.core.**

# local_auth uses AndroidX biometric through reflection-free calls, but keep
# FragmentActivity subclasses intact (MainActivity extends FlutterFragmentActivity).
-keep class androidx.fragment.app.FragmentActivity { *; }

# flutter_secure_storage: keep Tink/crypto classes used for key storage.
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
