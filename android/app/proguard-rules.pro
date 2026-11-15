# Flutter Core
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Desugaring
-keep class java.time.** { *; }
-dontwarn java.time.**

# Keep attributes for reflection & serialization
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Supabase / WebSockets / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**
