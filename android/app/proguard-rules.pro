# ==============================================================================
# ProGuard & R8 Optimization Rules for ShopiQ (Flutter Production Release)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Flutter Framework & Plugin Engine
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Deferred components / Play Core keep & suppress
-dontwarn com.google.android.play.core.**

# Application main activity
-keep class in.inventq.shopiq.MainActivity { *; }

# ------------------------------------------------------------------------------
# 2. Kotlin Runtime & Coroutines
# ------------------------------------------------------------------------------
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**

# ------------------------------------------------------------------------------
# 3. Stack Trace Deobfuscation & Play Console Crash Diagnostics
# ------------------------------------------------------------------------------
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# ------------------------------------------------------------------------------
# 4. Networking & HTTP Libraries
# ------------------------------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ------------------------------------------------------------------------------
# 5. Serialization & Data Models
# ------------------------------------------------------------------------------
-keepclassmembers enum * { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ------------------------------------------------------------------------------
# 6. AndroidX & Jetpack Libraries
# ------------------------------------------------------------------------------
-dontwarn androidx.**
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Suppress harmless third-party warnings
-dontwarn javax.annotation.**
-dontwarn org.bouncycastle.**
