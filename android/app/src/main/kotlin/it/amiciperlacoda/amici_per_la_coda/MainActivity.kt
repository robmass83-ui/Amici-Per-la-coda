package it.amiciperlacoda.amici_per_la_coda

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "it.amiciperlacoda.amici_per_la_coda/updater"
    private val notificationChannelId = "aggiornamenti"
    private val notificationId = 41
    private val mainHandler = Handler(Looper.getMainLooper())

    private var updaterChannel: MethodChannel? = null
    private var installResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        InstallResultReceiver.listener = { intent -> onInstallResult(intent) }
        updaterChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        )
        updaterChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getVersion" -> result.success(versionMap())
                "getDownloadPath" -> result.success(downloadFile().absolutePath)
                "canInstallPackages" -> result.success(canInstallPackages())
                "requestInstallPermission" -> {
                    requestInstallPermission()
                    result.success(null)
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(null)
                }
                "showUpdateNotification" -> {
                    val title = call.argument<String>("title") ?: "Nuova versione"
                    val body = call.argument<String>("body") ?: ""
                    showUpdateNotification(title, body)
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("missing", "Percorso APK mancante.", null)
                    } else {
                        try {
                            installApk(path, result)
                        } catch (error: Exception) {
                            result.error("install", error.message ?: "Installazione non riuscita.", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (InstallResultReceiver.listener != null) {
            InstallResultReceiver.listener = null
        }
        super.onDestroy()
    }

    private fun versionMap(): Map<String, Any> {
        val info = installedPackageInfo(0)
        return mapOf(
            "versionName" to (info.versionName ?: "0.0.0"),
            "versionCode" to versionCodeOf(info),
            "abis" to Build.SUPPORTED_ABIS.toList(),
        )
    }

    private fun downloadFile(): File {
        val dir = File(cacheDir, "updates")
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return File(dir, "update.apk")
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 2401)
            }
        }
    }

    private fun showUpdateNotification(title: String, body: String) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    notificationChannelId,
                    "Aggiornamenti app",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                return
            }
        }
        val launch = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pending)
            .setAutoCancel(true)
            .build()
        manager.notify(notificationId, notification)
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists() || file.length() < 1024 * 1024) {
            throw IllegalStateException("APK non valido o danneggiato.")
        }
        assertCompatibleUpdate(file)
        installResult?.error("install", "Installazione sostituita da una nuova.", null)
        installResult = result

        val installer = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(packageName)
        params.setSize(file.length())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_REQUIRED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            params.setRequestUpdateOwnership(true)
        }
        val sessionId = installer.createSession(params)
        val session = installer.openSession(sessionId)
        try {
            session.openWrite("update.apk", 0, file.length()).use { out ->
                file.inputStream().use { input -> input.copyTo(out) }
                session.fsync(out)
            }
            val callback = Intent(this, InstallResultReceiver::class.java).apply {
                action = InstallResultReceiver.ACTION
            }
            val pending = PendingIntent.getBroadcast(
                this,
                sessionId,
                callback,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            session.commit(pending.intentSender)
        } catch (error: Exception) {
            session.abandon()
            installResult = null
            throw error
        } finally {
            session.close()
        }
    }

    private fun assertCompatibleUpdate(file: File) {
        val parsed = packageArchiveInfo(file.absolutePath)
            ?: throw IllegalStateException("APK non valido o danneggiato.")
        parsed.applicationInfo?.sourceDir = file.absolutePath
        parsed.applicationInfo?.publicSourceDir = file.absolutePath
        if (parsed.packageName != packageName) {
            throw IllegalStateException("L'APK non è Amici per la Coda.")
        }
        val incoming = versionCodeOf(parsed)
        val installed = versionCodeOf(installedPackageInfo(0))
        if (incoming <= installed) {
            throw IllegalStateException(
                "Android non installa una versione uguale o più vecchia " +
                    "(codice $incoming, sul telefono c'è $installed).",
            )
        }
        val incomingCerts = signingSha256(parsed)
        val installedCerts = signingSha256(
            installedPackageInfo(signingFlags()),
        )
        if (incomingCerts.isNotEmpty() &&
            installedCerts.isNotEmpty() &&
            incomingCerts.none { installedCerts.contains(it) }
        ) {
            throw IllegalStateException(
                "La firma di questa build non coincide con l'app installata. " +
                    "I dati restano su Firebase: disinstalla e reinstalla una volta sola.",
            )
        }
    }

    private fun onInstallResult(intent: Intent) {
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE,
        )
        if (status == PackageInstaller.STATUS_PENDING_USER_ACTION) {
            val confirm = extraIntent(intent) ?: return
            confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(confirm)
            return
        }
        val pending = installResult ?: return
        installResult = null
        mainHandler.post {
            if (status == PackageInstaller.STATUS_SUCCESS) {
                pending.success(null)
            } else {
                pending.error("install", installStatusMessage(status, intent), null)
            }
        }
    }

    private fun installStatusMessage(status: Int, intent: Intent): String {
        val detail = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE).orEmpty()
        val lowered = detail.lowercase()
        if (lowered.contains("version") || lowered.contains("downgrade")) {
            return "Android non installa una versione uguale o più vecchia."
        }
        if (lowered.contains("incompatible") || lowered.contains("signature") ||
            lowered.contains("update_incompatible")
        ) {
            return "La firma di questa build non coincide con l'app installata. " +
                "I dati restano su Firebase: disinstalla e reinstalla una volta sola."
        }
        return when (status) {
            PackageInstaller.STATUS_FAILURE_ABORTED -> "Installazione annullata."
            PackageInstaller.STATUS_FAILURE_CONFLICT,
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE,
            ->
                "La firma di questa build non coincide con l'app installata. " +
                    "I dati restano su Firebase: disinstalla e reinstalla una volta sola."
            PackageInstaller.STATUS_FAILURE_INVALID -> "APK non valido o danneggiato."
            PackageInstaller.STATUS_FAILURE_STORAGE -> "Spazio insufficiente per installare l'aggiornamento."
            else ->
                if (detail.isBlank()) {
                    "Installazione non riuscita."
                } else {
                    "Installazione non riuscita. $detail"
                }
        }
    }

    private fun extraIntent(intent: Intent): Intent? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_INTENT)
        }
    }

    private fun installedPackageInfo(flags: Int): PackageInfo {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, flags)
        }
    }

    private fun packageArchiveInfo(path: String): PackageInfo? {
        val flags = signingFlags()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageArchiveInfo(
                path,
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(path, flags)
        }
    }

    private fun signingFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }
    }

    private fun versionCodeOf(info: PackageInfo): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode.toInt()
        } else {
            @Suppress("DEPRECATION")
            info.versionCode
        }
    }

    private fun signingSha256(info: PackageInfo): Set<String> {
        val bytes = mutableListOf<ByteArray>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signing = info.signingInfo ?: return emptySet()
            val signers = if (signing.hasMultipleSigners()) {
                signing.apkContentsSigners
            } else {
                signing.signingCertificateHistory
            }
            for (signer in signers) {
                bytes.add(signer.toByteArray())
            }
        } else {
            @Suppress("DEPRECATION")
            val signatures = info.signatures ?: return emptySet()
            for (signature in signatures) {
                bytes.add(signature.toByteArray())
            }
        }
        val digest = MessageDigest.getInstance("SHA-256")
        return bytes.map { cert ->
            digest.reset()
            digest.digest(cert).joinToString("") { byte -> "%02x".format(byte) }
        }.toSet()
    }
}

class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        listener?.invoke(intent)
    }

    companion object {
        const val ACTION = "it.amiciperlacoda.amici_per_la_coda.INSTALL_RESULT"

        @Volatile
        var listener: ((Intent) -> Unit)? = null
    }
}
