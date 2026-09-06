package org.holosmusic.holos_music

import android.app.Activity
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicLong

class MainActivity : FlutterActivity() {
    private val requestCode = 4101
    private var pickerResult: MethodChannel.Result? = null
    private val leases = ConcurrentHashMap<String, ParcelFileDescriptor>()
    private val sequence = AtomicLong()
    private val worker = Executors.newSingleThreadExecutor()
    private lateinit var library: LocalLibrary
    private var folderResult: MethodChannel.Result? = null
    private val folderRequestCode = 4102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        library = LocalLibrary(this)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "org.holosmusic/library_progress")
            .setStreamHandler(library)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.holosmusic/library")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> library.load(result)
                    "scan" -> library.scan(result)
                    "cancel" -> library.cancel(result)
                    "forgetFolder" -> library.forgetFolder(call.argument<String>("uri") ?: "", result)
                    "pickFolder" -> {
                        if (folderResult != null || pickerResult != null) {
                            result.error("picker_busy", "File selection is already open.", null)
                        } else {
                            folderResult = result
                            try {
                                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                    putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                                }
                                startActivityForResult(intent, folderRequestCode)
                            } catch (_: Exception) {
                                folderResult = null
                                result.error("picker_unavailable", "No folder picker is available.", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "org.holosmusic/local_flac")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickFlac" -> {
                        if (pickerResult != null || folderResult != null) {
                            result.error("picker_busy", "File selection is already open.", null)
                        } else {
                            pickerResult = result
                            try {
                                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = "*/*"
                                    putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                                    putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                                        "audio/flac", "audio/x-flac", "audio/*", "application/octet-stream"
                                    ))
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivityForResult(intent, requestCode)
                            } catch (_: Exception) {
                                pickerResult = null
                                result.error("picker_unavailable", "No document picker is available.", null)
                            }
                        }
                    }
                    "release" -> {
                        call.argument<String>("leaseId")?.let { leases.remove(it)?.close() }
                        result.success(null)
                    }
                    "openLibraryFile" -> {
                        val uri = call.argument<String>("uri")?.let(Uri::parse)
                        if (uri == null || uri.scheme != "content") {
                            result.error("access_denied", "Invalid local document.", null)
                        } else openDocument(uri, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result bridge for FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == folderRequestCode) {
            val result = folderResult ?: return
            folderResult = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return }
            try {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                library.addFolder(uri, result)
            } catch (_: Exception) {
                result.error("access_denied", "Could not retain folder access. Select it again.", null)
            }
            return
        }
        if (requestCode != this.requestCode) return
        val result = pickerResult ?: return
        pickerResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        openDocument(uri, result)
    }

    private fun openDocument(uri: Uri, result: MethodChannel.Result) {
        worker.execute {
            var descriptor: ParcelFileDescriptor? = null
            try {
                // Validate FLAC's actual header rather than trusting a name or MIME type.
                val header = contentResolver.openInputStream(uri)?.use(FlacHeader::read)
                    ?: throw SecurityException("File unavailable")
                descriptor = contentResolver.openFileDescriptor(uri, "r")
                    ?: throw SecurityException("File unavailable")
                val name = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                    ?.use { cursor ->
                        if (cursor.moveToFirst()) cursor.getString(0) else null
                    } ?: "Local FLAC file"
                var title: String? = null
                var artist: String? = null
                val metadata = MediaMetadataRetriever()
                try {
                    metadata.setDataSource(descriptor.fileDescriptor)
                    title = metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                    artist = metadata.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
                } catch (_: Exception) {
                    // Missing/unreadable tags must not prevent ordinary FLAC playback.
                } finally {
                    metadata.release()
                }
                val leaseId = sequence.incrementAndGet().toString()
                val held = requireNotNull(descriptor)
                val response = mapOf(
                    "leaseId" to leaseId,
                    // Mornye's copied Android audio plugin duplicates this granted FD.
                    "path" to "/proc/self/fd/${held.fd}",
                    "name" to name,
                    "title" to (title?.takeIf { it.isNotBlank() } ?: name.removeSuffix(".flac").removeSuffix(".FLAC")),
                    "artist" to (artist?.takeIf { it.isNotBlank() } ?: "Unknown artist"),
                    "durationMs" to header.durationMs,
                    "sampleRate" to header.sampleRate,
                    "bitDepth" to header.bitDepth
                )
                runOnUiThread {
                    if (isDestroyed || isFinishing) {
                        held.close()
                    } else {
                        leases[leaseId] = held
                        result.success(response)
                    }
                }
                descriptor = null // Ownership transferred to main-thread callback.
            } catch (_: SecurityException) {
                runOnUiThread { if (!isDestroyed) result.error("access_denied", "File access denied.", null) }
            } catch (_: IllegalArgumentException) {
                runOnUiThread { if (!isDestroyed) result.error("not_flac", "Invalid FLAC header.", null) }
            } catch (_: Exception) {
                runOnUiThread { if (!isDestroyed) result.error("file_unavailable", "Could not read this file.", null) }
            } finally {
                descriptor?.close()
            }
        }
    }

    override fun onDestroy() {
        folderResult?.error("activity_closed", "Folder selection closed.", null)
        folderResult = null
        if (::library.isInitialized) library.close()
        pickerResult?.error("activity_closed", "File selection closed.", null)
        pickerResult = null
        super.onDestroy()
        worker.shutdownNow()
        leases.values.forEach { runCatching { it.close() } }
        leases.clear()
    }
}
