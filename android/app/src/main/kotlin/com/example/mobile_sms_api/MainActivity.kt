package com.example.mobile_sms_api

import android.app.PendingIntent
import android.content.*
import android.os.Bundle
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "native_sms"
    private var smsReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d("TEST_LOG", "🔥 APP OPENED")

        registerSmsReceiver()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ---------------- SMS CHANNEL ----------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_sms")
            .setMethodCallHandler { call, result ->

                if (call.method == "sendSms") {
                    val phone = call.argument<String>("phone") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val simSlot = call.argument<Int>("sim") ?: 0

                    val ok = sendSms(phone, message, simSlot)

                    result.success(mapOf("success" to ok))
                } else {
                    result.notImplemented()
                }
            }

        // ---------------- SIM INFO CHANNEL ----------------
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sim_info")
            .setMethodCallHandler { call, result ->

                if (call.method == "getSimInfo") {
                    try {
                        val subManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
                                as SubscriptionManager

                        val activeSubs = subManager.activeSubscriptionInfoList
                        val simList = mutableListOf<Map<String, Any>>()

                        if (activeSubs != null) {
                            for (info in activeSubs) {


                                simList.add(
                                    mapOf(
                                        "carrierName" to (info.carrierName?.toString() ?: "Unknown"),
                                        "slotIndex" to info.simSlotIndex,
                                        "subscriptionId" to info.subscriptionId,
                                        "number" to (info.number ?: "Unknown")
                                    )
                                )
                            }
                        }

                        result.success(simList)

                    } catch (e: Exception) {
                        result.error("SIM_ERROR", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    // ---------------- SEND SMS ----------------
    private fun sendSms(phone: String, message: String, simSlot: Int): Boolean {
        try {
            val subManager =
                getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

            val subs = subManager.activeSubscriptionInfoList

            if (subs.isNullOrEmpty()) {
                Log.e("SMS_LOG", "❌ No active SIM found")
                return false
            }

            val simInfo = subs.firstOrNull { it.simSlotIndex == simSlot } ?: subs[0]

            val smsManager =
                SmsManager.getSmsManagerForSubscriptionId(simInfo.subscriptionId)

            val sentIntent = PendingIntent.getBroadcast(
                this,
                0,
                Intent("SMS_SENT"),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            smsManager.sendTextMessage(
                phone,
                null,
                message,
                sentIntent,
                null
            )

            Log.d("SMS_LOG", "📤 SMS via SIM ${simInfo.simSlotIndex} → $phone")

            return true

        } catch (e: Exception) {
            Log.e("SMS_LOG", "❌ SMS ERROR: ${e.message}")
            return false
        }
    }

    // ---------------- RECEIVER ----------------
    private fun registerSmsReceiver() {
        val filter = IntentFilter("SMS_SENT")

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (resultCode) {
                    RESULT_OK -> Log.d("SMS_LOG", "✅ SMS sent")
                    SmsManager.RESULT_ERROR_GENERIC_FAILURE -> Log.e("SMS_LOG", "❌ Generic failure")
                    SmsManager.RESULT_ERROR_NO_SERVICE -> Log.e("SMS_LOG", "❌ No service")
                    SmsManager.RESULT_ERROR_NULL_PDU -> Log.e("SMS_LOG", "❌ Null PDU")
                    SmsManager.RESULT_ERROR_RADIO_OFF -> Log.e("SMS_LOG", "❌ Radio off")
                    else -> Log.e("SMS_LOG", "❌ Unknown error")
                }
            }
        }

        registerReceiver(smsReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        smsReceiver?.let { unregisterReceiver(it) }
    }
}
