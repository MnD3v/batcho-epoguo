package com.equilibre.boisetvis

import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  /** Alertes façon Duolingo, programmées en natif (lib/services/android_alerts.dart). */
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    AlertNotifier.createChannels(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "boisetvis/alerts")
        .setMethodCallHandler { call, result ->
          try {
            when (call.method) {
              "scheduleWeekly" -> {
                val alerts = call.argument<List<Map<*, *>>>("alerts") ?: emptyList()
                AlertStore.replaceWeekly(this, alerts.map { Alert.fromMap(it) })
                result.success(null)
              }
              "scheduleOnce" -> {
                AlertStore.put(this, Alert.fromMap(call.arguments as Map<*, *>))
                result.success(null)
              }
              "showNow" -> {
                AlertNotifier.show(this, Alert.fromMap(call.arguments as Map<*, *>))
                result.success(null)
              }
              "cancel" -> {
                AlertStore.remove(this, call.argument<Int>("id") ?: -1)
                result.success(null)
              }
              "cancelAll" -> {
                AlertStore.clear(this)
                NotificationManagerCompat.from(this).cancelAll()
                result.success(null)
              }
              else -> result.notImplemented()
            }
          } catch (e: Exception) {
            result.error("alerts", e.message, null)
          }
        }
  }
}
