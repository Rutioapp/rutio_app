package com.rutio.app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    companion object {
        private const val NOTIFICATION_CHANNEL = "rutio/notification_permission"
        private const val SCHEDULED_NOTIFICATIONS_PREFS = "scheduled_notifications"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimeZone" -> result.success(TimeZone.getDefault().id)
                "clearScheduledNotificationsCache" -> {
                    val cleared = applicationContext
                        .getSharedPreferences(SCHEDULED_NOTIFICATIONS_PREFS, Context.MODE_PRIVATE)
                        .edit()
                        .clear()
                        .commit()
                    result.success(cleared)
                }
                else -> result.notImplemented()
            }
        }
    }
}
