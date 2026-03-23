package com.example.mobile_sms_api

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class SmsFcmService : FirebaseMessagingService() {

    private val TAG = "SMS_FCM"

    // 🔥 Called automatically by :contentReference[oaicite:0]{index=0}
    override fun onNewToken(token: String) {
        super.onNewToken(token)

        Log.d(TAG, "🔥 NEW TOKEN: $token")

        sendTokenToServer(token)
    }

    override fun onMessageReceived(msg: RemoteMessage) {
        super.onMessageReceived(msg)

        Log.d(TAG, "📩 FCM RECEIVED: ${msg.data}")

        val data = msg.data

        if (data["type"] == "SEND_SMS") {
            val phone = data["phone"] ?: return
            val message = data["message"] ?: return
            val simSlot = data["sim"]?.toIntOrNull() ?: 0

            sendSms(phone, message, simSlot)
        }
    }

    private fun sendSms(phone: String, message: String, simSlot: Int) {

        // ✅ Permission check
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.SEND_SMS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.e(TAG, "❌ SEND_SMS permission not granted")
            return
        }

        try {
            val subManager =
                getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

            val subs = subManager.activeSubscriptionInfoList

            if (subs.isNullOrEmpty()) {
                Log.e(TAG, "❌ No SIM available")
                return
            }

            val simInfo = subs.getOrNull(simSlot) ?: subs[0]

            val manager =
                SmsManager.getSmsManagerForSubscriptionId(simInfo.subscriptionId)

            val sentPI = PendingIntent.getBroadcast(
                this,
                0,
                Intent("SMS_SENT"),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            manager.sendTextMessage(
                phone,
                null,
                message,
                sentPI,
                null
            )

            Log.d(TAG, "✅ SMS SENT → $phone via SIM ${simInfo.simSlotIndex}")

        } catch (e: Exception) {
            Log.e(TAG, "❌ SMS ERROR: ${e.message}")
        }
    }

    private fun sendTokenToServer(token: String) {
        Log.d(TAG, "📤 Send token to backend: $token")

        // TODO: call your API
    }
}
