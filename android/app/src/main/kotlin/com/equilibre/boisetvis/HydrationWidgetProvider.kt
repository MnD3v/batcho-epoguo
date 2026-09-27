package com.equilibre.boisetvis

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget de l'écran d'accueil : litres bus, jauge, flamme et « J'ai bu ✓ ». */
class HydrationWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.hydration_widget).apply {
            setTextViewText(R.id.widget_drunk, widgetData.getString("drunk", "0 L"))
            setTextViewText(R.id.widget_goal, widgetData.getString("goal", ""))
            setTextViewText(
                R.id.widget_status,
                widgetData.getString("status", null) ?: "Ouvre l'appli pour commencer",
            )
            setTextViewText(R.id.widget_streak, widgetData.getString("streak", "0"))
            setProgressBar(R.id.widget_progress, 100, readProgress(widgetData), false)

            // Toucher le widget ouvre l'appli.
            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            // « J'ai bu ✓ » coche l'alerte en cours sans ouvrir l'appli.
            val canCheck = widgetData.getBoolean("canCheck", false)
            setViewVisibility(R.id.widget_drank, if (canCheck) View.VISIBLE else View.GONE)
            setOnClickPendingIntent(
                R.id.widget_drank,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("boisetvis://drank")),
            )
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  /** La jauge est enregistrée en entier (0 à 100), parfois en Long. */
  private fun readProgress(data: SharedPreferences): Int =
      when (val value = data.all["progress"]) {
        is Int -> value
        is Long -> value.toInt()
        else -> 0
      }
}
