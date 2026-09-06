// SAF selection/traversal adapted from Mornye's MainActivitySafTreePicker.kt,
// MainActivitySafScan.kt and SafTreeListing.kt; Copyright 2026 zarzet.
// SPDX-License-Identifier: LGPL-3.0-only
package org.holosmusic.holos_music

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.AtomicFile
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.ArrayDeque
import java.util.concurrent.CancellationException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Private metadata cache only. This class never modifies/deletes source music. */
internal class LocalLibrary(private val activity: MainActivity) : EventChannel.StreamHandler {
    private val resolver get() = activity.contentResolver
    private val worker = Executors.newSingleThreadExecutor()
    private val cancelled = AtomicBoolean(false)
    private val scanning = AtomicBoolean(false)
    private val storeFile = AtomicFile(File(activity.filesDir, "local-library-v1.json"))
    private var cached: JSONObject? = null
    @Volatile private var closed = false
    private var eventSink: EventChannel.EventSink? = null
    private var checked = 0
    private var found = 0
    private var skipped = 0
    private var lastProgress = 0L

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
    override fun onCancel(arguments: Any?) { eventSink = null }

    private fun post(block: () -> Unit) {
        activity.runOnUiThread { if (!closed && !activity.isDestroyed) block() }
    }

    private fun read(): JSONObject {
        cached?.let { return JSONObject(it.toString()) }
        val value = if (storeFile.baseFile.exists() || File(storeFile.baseFile.path + ".bak").exists()) {
            JSONObject(storeFile.readFully().toString(Charsets.UTF_8))
        } else JSONObject().put("version", 1).put("folders", JSONArray()).put("tracks", JSONArray())
        require(value.getInt("version") == 1) { "Unsupported library format" }
        cached = value
        return JSONObject(value.toString())
    }

    private fun save(value: JSONObject) {
        val stream = storeFile.startWrite()
        try {
            stream.write(value.toString().toByteArray(Charsets.UTF_8))
            storeFile.finishWrite(stream)
            cached = value
        } catch (error: Exception) {
            storeFile.failWrite(stream)
            throw error
        }
    }

    private fun hasGrant(uri: String): Boolean = resolver.persistedUriPermissions.any {
        it.isReadPermission && it.uri.toString() == uri
    }

    private fun snapshot(value: JSONObject): String {
        val folders = value.getJSONArray("folders")
        for (index in 0 until folders.length()) {
            val folder = folders.getJSONObject(index)
            folder.put("available", hasGrant(folder.getString("uri")) && folder.optBoolean("available", true))
        }
        return value.toString()
    }

    fun load(result: MethodChannel.Result) = operation(result) { snapshot(read()) }

    fun addFolder(uri: Uri, result: MethodChannel.Result) = operation(result) {
        val value = read()
        val folders = value.getJSONArray("folders")
        val document = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri))
        val name = resolver.query(document, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) it.getString(0) else null } ?: "Music folder"
        val folder = JSONObject().put("uri", uri.toString()).put("name", name).put("available", true)
        val existing = (0 until folders.length()).firstOrNull {
            folders.getJSONObject(it).getString("uri") == uri.toString()
        }
        if (existing == null) folders.put(folder) else folders.put(existing, folder)
        save(value)
        snapshot(value)
    }

    fun forgetFolder(uri: String, result: MethodChannel.Result) = operation(result) {
        val value = read()
        val folders = value.getJSONArray("folders")
        val tracks = value.getJSONArray("tracks")
        value.put("folders", JSONArray((0 until folders.length()).map { folders.getJSONObject(it) }
            .filter { it.getString("uri") != uri }))
        value.put("tracks", JSONArray((0 until tracks.length()).map { tracks.getJSONObject(it) }
            .filter { it.getString("folderUri") != uri }))
        save(value)
        runCatching { resolver.releasePersistableUriPermission(Uri.parse(uri), Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        snapshot(value)
    }

    private fun operation(result: MethodChannel.Result, action: () -> String) {
        if (scanning.get()) { result.error("scan_busy", "A scan is already running.", null); return }
        worker.execute {
            try {
                val response = action()
                post { result.success(response) }
            } catch (_: SecurityException) {
                post { result.error("access_denied", "Select the folder again to restore access.", null) }
            } catch (_: Exception) {
                post { result.error("library_failed", "Could not read or save the local library.", null) }
            }
        }
    }

    fun cancel(result: MethodChannel.Result) { cancelled.set(true); result.success(null) }

    private fun checkpoint() {
        if (cancelled.get() || closed || Thread.currentThread().isInterrupted) throw CancellationException()
    }

    private fun progress(force: Boolean = false) {
        val now = System.currentTimeMillis()
        if (!force && now - lastProgress < 120) return
        lastProgress = now
        val payload = mapOf("checked" to checked, "found" to found, "skipped" to skipped)
        post { eventSink?.success(payload) }
    }

    fun scan(result: MethodChannel.Result) {
        if (!scanning.compareAndSet(false, true)) {
            result.error("scan_busy", "A scan is already running.", null); return
        }
        cancelled.set(false)
        worker.execute {
            checked = 0; found = 0; skipped = 0; lastProgress = 0
            try {
                val value = read()
                val folders = value.getJSONArray("folders")
                val previous = value.getJSONArray("tracks")
                val songs = linkedMapOf<String, JSONObject>()
                var unavailable = 0
                for (index in 0 until folders.length()) {
                    checkpoint()
                    val folder = folders.getJSONObject(index)
                    val root = folder.getString("uri")
                    try {
                        if (!hasGrant(root)) throw SecurityException()
                        val scanned = scanTree(Uri.parse(root))
                        scanned.forEach { songs[it.getString("id")] = it }
                        folder.put("available", true).remove("problem")
                    } catch (error: CancellationException) { throw error
                    } catch (error: Exception) {
                        unavailable++
                        folder.put("available", false).put("problem",
                            if (error is SecurityException) "access_denied" else "scan_failed")
                        // Failed folders retain the old cache, explicitly unavailable.
                        for (songIndex in 0 until previous.length()) {
                            val song = previous.getJSONObject(songIndex)
                            if (song.getString("folderUri") == root) songs.putIfAbsent(song.getString("id"), song)
                        }
                    }
                }
                checkpoint()
                val ordered = songs.values.sortedWith(compareBy<JSONObject> {
                    it.getString("title").lowercase(java.util.Locale.ROOT)
                }.thenBy { it.getString("id") })
                value.put("tracks", JSONArray(ordered)).put("skipped", skipped)
                    .put("unavailableFolders", unavailable).put("scannedAt", System.currentTimeMillis())
                checkpoint()
                save(value)
                progress(true)
                val response = snapshot(value)
                scanning.set(false)
                post { result.success(response) }
            } catch (_: CancellationException) {
                post { result.error("scan_cancelled", "Previous library kept.", null) }
            } catch (_: Exception) {
                post { result.error("scan_failed", "Scan failed. Previous library kept.", null) }
            } finally { scanning.set(false) }
        }
    }

    private fun scanTree(root: Uri): List<JSONObject> {
        val rootString = root.toString()
        val pending = ArrayDeque<String>()
        val visited = hashSetOf<String>()
        val songs = arrayListOf<JSONObject>()
        pending.add(DocumentsContract.getTreeDocumentId(root))
        val columns = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE)
        while (pending.isNotEmpty()) {
            checkpoint()
            val directoryId = pending.removeFirst()
            if (!visited.add(directoryId)) continue
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(root, directoryId)
            val cursor = resolver.query(children, columns, null, null, null)
                ?: throw java.io.IOException("Folder unavailable")
            cursor.use {
                while (it.moveToNext()) {
                    checkpoint()
                    val id = it.getString(0)
                    val name = it.getString(1) ?: "Local FLAC file"
                    val mime = it.getString(2) ?: ""
                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) { pending.add(id); continue }
                    checked++
                    if (name.endsWith(".flac", true) || mime == "audio/flac" || mime == "audio/x-flac") {
                        val uri = DocumentsContract.buildDocumentUriUsingTree(root, id)
                        try {
                            val metadata = FlacMetadata.read(activity, uri, name)
                            metadata.put("id", "${root.authority}:$id").put("uri", uri.toString())
                                .put("folderUri", rootString)
                            songs.add(metadata); found++
                        } catch (error: CancellationException) { throw error
                        } catch (_: Exception) { skipped++ }
                    }
                    progress()
                }
            }
        }
        return songs
    }

    fun close() {
        closed = true; cancelled.set(true); eventSink = null; worker.shutdownNow()
    }
}
