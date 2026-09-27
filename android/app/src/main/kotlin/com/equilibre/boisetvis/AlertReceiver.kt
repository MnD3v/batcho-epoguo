package com.equilibre.boisetvis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.app.NotificationManagerCompat
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Heure d'une alerte, et boutons « J'ai bu ✓ » / « Plus tard ». */
class AlertReceiver : BroadcastReceiver() {

  override fun onReceive(context: Context, intent: Intent) {
    val id = intent.getIntExtra(EXTRA_ID, -1)
    when (intent.action) {
      ACTION_FIRE -> {
        val alert = AlertStore.get(context, id) ?: return
        // Alerte de la semaine : on programme déjà la suivante.
        if (alert.weekly) AlertStore.arm(context, alert) else AlertStore.remove(context, id)
        if (id == RESCUE_ID && rescueCancelledToday(context)) return
        AlertNotifier.show(context, alert)
      }
      ACTION_DRANK -> {
        NotificationManagerCompat.from(context).cancel(id)
        val minutes = readAlert(intent)?.reminderMinutes?.takeIf { it >= 0 }
        // Coche en arrière-plan avec le code Dart, comme le bouton du widget.
        val uri =
            Uri.parse(
                if (minutes != null) "boisetvis://drank?minutes=$minutes" else "boisetvis://drank")
        try {
          HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
        } catch (e: Exception) {
          // L'appli cochera à la main.
        }
      }
      ACTION_SNOOZE -> {
        NotificationManagerCompat.from(context).cancel(id)
        val alert = readAlert(intent) ?: return
        AlertStore.put(
            context,
            alert.copy(
                id = SNOOZE_BASE_ID + alert.reminderMinutes,
                // Reno s'inquiète un peu : c'est la deuxième fois.
                mood = 1,
                weekday = 0,
                at = System.currentTimeMillis() + SNOOZE_MS,
            ),
        )
      }
    }
  }

  private fun readAlert(intent: Intent): Alert? =
      try {
        intent.getStringExtra(EXTRA_ALERT)?.let { Alert.fromJson(JSONObject(it)) }
      } catch (e: Exception) {
        null
      }

  /**
   * Le soir, la flamme a pu être sauvée depuis la notification ou le widget
   * (code Dart en arrière-plan, qui ne peut pas annuler l'alarme) : il note
   * alors le jour dans ses préférences.
   */
  private fun rescueCancelledToday(context: Context): Boolean {
    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    return prefs.getString("flutter.rescue_off_day", null) == today
  }

  companion object {
    const val ACTION_FIRE = "com.equilibre.boisetvis.ALERT"
    const val ACTION_DRANK = "com.equilibre.boisetvis.DRANK"
    const val ACTION_SNOOZE = "com.equilibre.boisetvis.SNOOZE"
    const val EXTRA_ID = "id"
    const val EXTRA_ALERT = "alert"

    /** Mêmes numéros que côté Dart (lib/services/android_alerts.dart). */
    const val RESCUE_ID = 800000
    const val SNOOZE_BASE_ID = 900000
    const val SNOOZE_MS = 15 * 60 * 1000L
  }
}

/** Redémarrage, mise à jour de l'appli ou changement d'heure : on reprogramme. */
class AlertBootReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    AlertStore.rearmAll(context)
  }
}
