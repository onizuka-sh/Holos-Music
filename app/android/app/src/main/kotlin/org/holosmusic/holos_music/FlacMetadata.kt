package org.holosmusic.holos_music

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import org.json.JSONObject

/** Validated local FLAC metadata reader for folder scanning. */
internal object FlacMetadata {
    fun read(context: Context, uri: Uri, name: String): JSONObject {
        val header = context.contentResolver.openInputStream(uri)?.use(FlacHeader::read)
            ?: throw SecurityException("File unavailable")
        var title: String? = null
        var artist: String? = null
        context.contentResolver.openFileDescriptor(uri, "r")?.use { descriptor ->
            val retriever = MediaMetadataRetriever()
            try {
                retriever.setDataSource(descriptor.fileDescriptor)
                title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            } catch (_: Exception) {
                // Tags are optional; valid FLAC can still play without them.
            } finally { retriever.release() }
        } ?: throw SecurityException("File unavailable")
        return JSONObject().put("name", name)
            .put("title", title?.takeIf { it.isNotBlank() } ?: name.replace(Regex("(?i)\\.flac$"), ""))
            .put("artist", artist?.takeIf { it.isNotBlank() } ?: "Unknown artist")
            .put("durationMs", header.durationMs).put("sampleRate", header.sampleRate)
            .put("bitDepth", header.bitDepth)
    }
}
