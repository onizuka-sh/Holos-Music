package org.holosmusic.holos_music

import java.io.InputStream

/** Minimal bounded STREAMINFO validation; it never decodes or buffers the audio. */
data class FlacHeader(val sampleRate: Int, val bitDepth: Int, val totalSamples: Long) {
    val durationMs: Long get() = totalSamples * 1000L / sampleRate

    companion object {
        fun read(stream: InputStream): FlacHeader {
            var magic = readExactly(stream, 4)
            if (magic[0] == 73.toByte() && magic[1] == 68.toByte() && magic[2] == 51.toByte()) {
                val tagHeader = readExactly(stream, 6)
                val sizes = tagHeader.copyOfRange(2, 6).map { it.toInt() and 0xff }
                require(sizes.all { it < 128 }) { "Invalid ID3 size" }
                val size = sizes.fold(0L) { value, byte -> (value shl 7) or byte.toLong() }
                require(size <= 16L * 1024 * 1024) { "ID3 prefix too large" }
                var remaining = size + if ((tagHeader[1].toInt() and 0x10) != 0) 10 else 0
                while (remaining > 0) {
                    val skipped = stream.skip(remaining)
                    if (skipped > 0) remaining -= skipped else {
                        require(stream.read() >= 0) { "Truncated ID3 prefix" }
                        remaining--
                    }
                }
                magic = readExactly(stream, 4)
            }
            require(magic.contentEquals(byteArrayOf(102, 76, 97, 67))) { "Not FLAC" }
            val block = readExactly(stream, 4)
            val size = ((block[1].toInt() and 255) shl 16) or
                ((block[2].toInt() and 255) shl 8) or (block[3].toInt() and 255)
            require((block[0].toInt() and 127) == 0 && size == 34) { "Missing STREAMINFO" }
            val info = readExactly(stream, 34)
            var packed = 0L
            for (index in 10..17) packed = (packed shl 8) or (info[index].toLong() and 255L)
            val sampleRate = (packed ushr 44).toInt()
            val bitDepth = ((packed ushr 36) and 31).toInt() + 1
            require(sampleRate in 1..655350 && bitDepth in 4..32) { "Invalid STREAMINFO" }
            return FlacHeader(sampleRate, bitDepth, packed and 0xFFFFFFFFFL)
        }

        private fun readExactly(stream: InputStream, count: Int): ByteArray {
            val bytes = ByteArray(count)
            var offset = 0
            while (offset < count) {
                val read = stream.read(bytes, offset, count - offset)
                require(read > 0) { "Truncated FLAC header" }
                offset += read
            }
            return bytes
        }
    }
}
