package com.equilibre.boisetvis

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Une alerte « bois ton eau » : chaque semaine ([weekday] 1 = lundi … 7 =
 * dimanche, à [minutes] depuis minuit) ou une seule fois (à [at], en ms).
 * Les textes sont préparés côté Dart (lib/services/android_alerts.dart).
 */
data class Alert(
    val id: Int,
    val title: String,
    val body: String,
    /** Visage de Reno : 0 = en larmes … 4 = très joyeux. */
    val mood: Int,
    val loud: Boolean,
    /** Heure de l'alerte cochée par « J'ai bu ✓ » (minutes depuis minuit). */
    val reminderMinutes: Int,
    val weekday: Int = 0,
    val minutes: Int = 0,
    val at: Long = 0L,
) {
  val weekly: Boolean
    get() = weekday in 1..7

  fun toJson(): JSONObject =
      JSONObject()
          .put("id", id)
          .put("title", title)
          .put("body", body)
          .put("mood", mood)
          .put("loud", loud)
          .put("reminderMinutes", reminderMinutes)
          .put("weekday", weekday)
          .put("minutes", minutes)
          .put("at", at)

  /** Prochaine sonnerie après [now]. */
  fun nextTime(now: Long = System.currentTimeMillis()): Long {
    if (!weekly) return at
    val cal =
        Calendar.getInstance().apply {
          timeInMillis = now
          set(Calendar.HOUR_OF_DAY, minutes / 60)
          set(Calendar.MINUTE, minutes % 60)
          set(Calendar.SECOND, 0)
          set(Calendar.MILLISECOND, 0)
        }
    // Calendar : dimanche = 1 … samedi = 7 ; Dart : lundi = 1 … dimanche = 7.
    val target = weekday % 7 + 1
    val days = (target - cal.get(Calendar.DAY_OF_WEEK) + 7) % 7
    cal.add(Calendar.DAY_OF_YEAR, days)
    if (cal.timeInMillis <= now) cal.add(Calendar.DAY_OF_YEAR, 7)
    return cal.timeInMillis
  }

  companion object {
    fun fromJson(o: JSONObject) =
        Alert(
            id = o.getInt("id"),
            title = o.getString("title"),
            body = o.getString("body"),
            mood = o.optInt("mood", 2),
            loud = o.optBoolean("loud", false),
            reminderMinutes = o.optInt("reminderMinutes", 0),
            weekday = o.optInt("weekday", 0),
            minutes = o.optInt("minutes", 0),
            at = o.optLong("at", 0L),
        )

    fun fromMap(m: Map<*, *>) =
        Alert(
            id = (m["id"] as Number).toInt(),
            title = m["title"] as String,
            body = m["body"] as String,
            mood = (m["mood"] as? Number)?.toInt() ?: 2,
            loud = m["loud"] as? Boolean ?: false,
            reminderMinutes = (m["reminderMinutes"] as? Number)?.toInt() ?: 0,
            weekday = (m["weekday"] as? Number)?.toInt() ?: 0,
            minutes = (m["minutes"] as? Number)?.toInt() ?: 0,
            at = (m["at"] as? Number)?.toLong() ?: 0L,
        )
  }
}

/**
 * Alertes programmées : gardées dans les préférences du téléphone (pour les
 * reprogrammer après un redémarrage) et confiées à AlarmManager.
 */
object AlertStore {
  private const val PREFS = "boisetvis_alerts"
  private const val KEY = "alerts"

  fun all(context: Context): List<Alert> {
    val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
    if (raw.isNullOrEmpty()) return emptyList()
    return try {
      val array = JSONArray(raw)
      (0 until array.length()).map { Alert.fromJson(array.getJSONObject(it)) }
    } catch (e: Exception) {
      emptyList()
    }
  }

  fun get(context: Context, id: Int): Alert? = all(context).firstOrNull { it.id == id }

  private fun save(context: Context, alerts: List<Alert>) {
    val array = JSONArray()
    alerts.forEach { array.put(it.toJson()) }
    context
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .edit()
        .putString(KEY, array.toString())
        .apply()
  }

  /** Remplace les alertes de la semaine (garde les alertes uniques). */
  fun replaceWeekly(context: Context, alerts: List<Alert>) {
    val current = all(context)
    current.filter { it.weekly }.forEach { cancelAlarm(context, it.id) }
    save(context, current.filter { !it.weekly } + alerts)
    alerts.forEach { arm(context, it) }
  }

  /** Ajoute ou remplace une alerte. */
  fun put(context: Context, alert: Alert) {
    cancelAlarm(context, alert.id)
    save(context, all(context).filter { it.id != alert.id } + alert)
    arm(context, alert)
  }

  fun remove(context: Context, id: Int) {
    cancelAlarm(context, id)
    save(context, all(context).filter { it.id != id })
  }

  fun clear(context: Context) {
    all(context).forEach { cancelAlarm(context, it.id) }
    save(context, emptyList())
  }

  /** Après un redémarrage ou un changement d'heure. */
  fun rearmAll(context: Context) {
    val now = System.currentTimeMillis()
    val (past, upcoming) = all(context).partition { !it.weekly && it.at <= now }
    if (past.isNotEmpty()) save(context, upcoming)
    upcoming.forEach { arm(context, it) }
  }

  fun arm(context: Context, alert: Alert) {
    val time = alert.nextTime()
    if (time <= System.currentTimeMillis()) return
    val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val intent = alarmIntent(context, alert.id)
    val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
    try {
      if (exact) {
        alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, intent)
      } else {
        // Heure exacte refusée : Android sonne à quelques minutes près.
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, intent)
      }
    } catch (e: SecurityException) {
      alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, intent)
    }
  }

  private fun cancelAlarm(context: Context, id: Int) {
    val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarms.cancel(alarmIntent(context, id))
  }

  private fun alarmIntent(context: Context, id: Int): PendingIntent =
      PendingIntent.getBroadcast(
          context,
          id,
          Intent(context, AlertReceiver::class.java)
              .setAction(AlertReceiver.ACTION_FIRE)
              .putExtra(AlertReceiver.EXTRA_ID, id),
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
}
