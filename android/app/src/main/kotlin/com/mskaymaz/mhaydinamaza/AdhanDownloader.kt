package com.mskaymaz.mhaydinamaza

import android.content.Context
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

object AdhanDownloader {
    fun download(
        context: Context,
        id: String?,
        fileName: String?,
        urlText: String?,
        result: MethodChannel.Result
    ) {
        val safeId = sanitizeFileName(id.orEmpty()).ifEmpty { "adhan" }
        val safeFileName = sanitizeFileName(fileName.orEmpty()).ifEmpty { "$safeId.mp3" }
        val remoteUrl = urlText?.trim().orEmpty()
        if (remoteUrl.isEmpty()) {
            result.error("adhan_url_missing", "Adhan URL is empty.", null)
            return
        }
        Thread {
            try {
                val targetDir = File(context.filesDir, "adhan")
                if (!targetDir.exists()) targetDir.mkdirs()
                val targetFile = File(targetDir, safeFileName)
                val connection = URL(remoteUrl).openConnection() as HttpURLConnection
                connection.connectTimeout = 15_000
                connection.readTimeout = 30_000
                connection.instanceFollowRedirects = true
                connection.connect()
                if (connection.responseCode !in 200..299) {
                    throw IllegalStateException("HTTP ${connection.responseCode}")
                }
                connection.inputStream.use { input ->
                    targetFile.outputStream().use { output -> input.copyTo(output) }
                }
                connection.disconnect()
                runResult(context, result) { result.success(targetFile.absolutePath) }
            } catch (error: Exception) {
                runResult(context, result) {
                    result.error("adhan_download_failed", error.message, null)
                }
            }
        }.start()
    }

    private fun runResult(
        context: Context,
        result: MethodChannel.Result,
        action: () -> Unit
    ) {
        if (context is MainActivity) {
            context.runOnUiThread { action() }
        } else {
            action()
        }
    }

    private fun sanitizeFileName(value: String): String {
        return value.replace(Regex("[^A-Za-z0-9._-]"), "_")
            .trim('_')
    }
}
