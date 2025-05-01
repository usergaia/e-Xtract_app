# TensorFlow Lite GPU Delegate keep rules
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }


# TensorFlow Lite GPU support
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**
