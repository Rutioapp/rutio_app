# Gson / TypeToken metadata required by flutter_local_notifications scheduled cache
-keepattributes Signature
-keepattributes *Annotation*
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep flutter_local_notifications models stable if minification is re-enabled later
-keep class com.dexterous.flutterlocalnotifications.** { *; }
