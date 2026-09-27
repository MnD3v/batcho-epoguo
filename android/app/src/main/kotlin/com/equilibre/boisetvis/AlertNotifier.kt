package com.equilibre.boisetvis

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.Person
import androidx.core.content.ContextCompat
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat

/**
 * Affiche une alerte comme Duolingo : notification « conversation » avec le
 * gros visage de Reno à gauche, le titre en gras en haut et le texte dessous.
 * Android ne la présente ainsi que si elle est liée à un raccourci
 * « conversation » (un par visage de Reno).
 */
object AlertNotifier {
  const val SOFT_CHANNEL = "bois_alertes"
  const val LOUD_CHANNEL = "bois_alertes_fortes"

  /** Canaux des versions précédentes (awesome_notifications). */
  private val OLD_CHANNELS =
      listOf("alertes_eau", "alertes_eau_fortes", "alertes_eau_v2", "alertes_eau_fortes_v2")

  private const val BLUE = 0xFF1CB0F6.toInt()

  /** « Glou-glou-glou… glouuup » : trois gorgées puis une longue. */
  private val SOFT_VIBRATION = longArrayOf(0, 90, 70, 90, 70, 90, 250, 450)

  /** En mode fort, le même rythme joué trois fois. */
  private val LOUD_VIBRATION =
      longArrayOf(
          0, 120, 80, 120, 80, 120, 300, 600, 500,
          120, 80, 120, 80, 120, 300, 600, 500,
          120, 80, 120, 80, 120, 300, 900,
      )

  private fun soundUri(context: Context, loud: Boolean): Uri =
      Uri.parse(
          "android.resource://${context.packageName}/" +
              (if (loud) R.raw.bois_fort else R.raw.bois_doux))

  fun createChannels(context: Context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = context.getSystemService(NotificationManager::class.java) ?: return
    OLD_CHANNELS.forEach { manager.deleteNotificationChannel(it) }
    manager.createNotificationChannel(
        channel(
            context,
            SOFT_CHANNEL,
            "Alertes pour boire",
            "Gouttes d'eau et carillon aux heures où tu dois boire",
            loud = false,
        ))
    manager.createNotificationChannel(
        channel(
            context,
            LOUD_CHANNEL,
            "Alertes fortes (réveil)",
            "Sonne comme un réveil aux heures où tu dois boire",
            loud = true,
        ))
  }

  @RequiresApi(Build.VERSION_CODES.O)
  private fun channel(
      context: Context,
      id: String,
      name: String,
      description: String,
      loud: Boolean,
  ): NotificationChannel {
    val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH)
    channel.description = description
    channel.enableVibration(true)
    channel.vibrationPattern = if (loud) LOUD_VIBRATION else SOFT_VIBRATION
    channel.enableLights(true)
    channel.lightColor = BLUE
    channel.setSound(
        soundUri(context, loud),
        AudioAttributes.Builder()
            .setUsage(
                if (loud) AudioAttributes.USAGE_ALARM else AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build(),
    )
    return channel
  }

  fun show(context: Context, alert: Alert) {
    if (Build.VERSION.SDK_INT >= 33 &&
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED) {
      return
    }
    createChannels(context)

    val avatar = loadAvatar(context, alert.mood)
    val icon =
        if (avatar != null) IconCompat.createWithBitmap(avatar)
        else IconCompat.createWithResource(context, R.mipmap.ic_launcher)
    val reno =
        Person.Builder().setKey("reno").setName(alert.title).setIcon(icon).setImportant(true).build()

    // Raccourci « conversation » : c'est lui qui donne le gros visage à gauche.
    val shortcutId = "reno_${alert.mood}"
    try {
      ShortcutManagerCompat.pushDynamicShortcut(
          context,
          ShortcutInfoCompat.Builder(context, shortcutId)
              .setShortLabel("Reno")
              .setLongLabel(alert.title)
              .setIcon(icon)
              .setIntent(launchIntent(context))
              .setLongLived(true)
              .setPerson(reno)
              .build(),
      )
    } catch (e: Exception) {
      // Sans raccourci : notification classique, toujours lisible.
    }

    val me = Person.Builder().setName("Moi").build()
    val style =
        NotificationCompat.MessagingStyle(me)
            .setConversationTitle(alert.title)
            .setGroupConversation(false)
            .addMessage(
                NotificationCompat.MessagingStyle.Message(
                    alert.body, System.currentTimeMillis(), reno))

    val builder =
        NotificationCompat.Builder(context, if (alert.loud) LOUD_CHANNEL else SOFT_CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(BLUE)
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setStyle(style)
            .setShortcutId(shortcutId)
            .setCategory(
                if (alert.loud) NotificationCompat.CATEGORY_ALARM
                else NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            // Avant Android 8 : son et vibration portés par la notification.
            .setSound(soundUri(context, alert.loud))
            .setVibrate(if (alert.loud) LOUD_VIBRATION else SOFT_VIBRATION)
            .setContentIntent(
                PendingIntent.getActivity(
                    context,
                    alert.id,
                    launchIntent(context),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ))
            .addAction(0, "J'ai bu ✓", actionIntent(context, AlertReceiver.ACTION_DRANK, alert))
            .addAction(
                0, "Plus tard (15 min)", actionIntent(context, AlertReceiver.ACTION_SNOOZE, alert))
    if (avatar != null) builder.setLargeIcon(avatar)

    val notification = builder.build()
    // Mode fort : sonne en boucle jusqu'à ce qu'on réponde, comme un réveil.
    if (alert.loud) notification.flags = notification.flags or Notification.FLAG_INSISTENT
    NotificationManagerCompat.from(context).notify(alert.id, notification)
  }

  /** Visage de Reno, pris dans les images de l'appli Flutter. */
  private fun loadAvatar(context: Context, mood: Int): Bitmap? =
      try {
        context.assets.open("flutter_assets/assets/notif/reno_mood_$mood.png").use {
          BitmapFactory.decodeStream(it)
        }
      } catch (e: Exception) {
        null
      }

  private fun launchIntent(context: Context): Intent =
      Intent(context, MainActivity::class.java)
          .setAction(Intent.ACTION_VIEW)
          .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)

  private fun actionIntent(context: Context, action: String, alert: Alert): PendingIntent =
      PendingIntent.getBroadcast(
          context,
          alert.id,
          Intent(context, AlertReceiver::class.java)
              .setAction(action)
              .putExtra(AlertReceiver.EXTRA_ID, alert.id)
              .putExtra(AlertReceiver.EXTRA_ALERT, alert.toJson().toString()),
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
}
