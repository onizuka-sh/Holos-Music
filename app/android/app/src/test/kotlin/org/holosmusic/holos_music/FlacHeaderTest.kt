package org.holosmusic.holos_music

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.io.ByteArrayInputStream

class FlacHeaderTest {
    private fun header(rate: Int = 44100, bits: Int = 16, samples: Long = 441000): ByteArray {
        val streamInfo = ByteArray(34)
        var packed = (rate.toLong() shl 44) or (1L shl 41) or
            ((bits - 1).toLong() shl 36) or samples
        for (index in 17 downTo 10) {
            streamInfo[index] = (packed and 255).toByte()
            packed = packed ushr 8
        }
        return byteArrayOf(102, 76, 97, 67, 0x80.toByte(), 0, 0, 34) + streamInfo
    }

    @Test fun readsSixteenBitStreamInfo() {
        val info = FlacHeader.read(ByteArrayInputStream(header()))
        assertEquals(44100, info.sampleRate)
        assertEquals(16, info.bitDepth)
        assertEquals(10000L, info.durationMs)
    }

    @Test fun readsHighResolutionStreamInfo() {
        val info = FlacHeader.read(ByteArrayInputStream(header(96000, 24, 960000)))
        assertEquals(96000, info.sampleRate)
        assertEquals(24, info.bitDepth)
        assertEquals(10000L, info.durationMs)
    }

    @Test fun supportsId3Prefix() {
        val id3 = byteArrayOf(73, 68, 51, 4, 0, 0, 0, 0, 0, 3, 1, 2, 3)
        assertEquals(16, FlacHeader.read(ByteArrayInputStream(id3 + header())).bitDepth)
    }

    @Test fun rejectsRenamedNonFlac() {
        assertThrows(IllegalArgumentException::class.java) {
            FlacHeader.read(ByteArrayInputStream(ByteArray(80)))
        }
    }

    @Test fun rejectsTruncatedAndInvalidStreamInfo() {
        assertThrows(IllegalArgumentException::class.java) {
            FlacHeader.read(ByteArrayInputStream(header().copyOf(24)))
        }
        assertThrows(IllegalArgumentException::class.java) {
            FlacHeader.read(ByteArrayInputStream(header(rate = 0)))
        }
        assertThrows(IllegalArgumentException::class.java) {
            FlacHeader.read(ByteArrayInputStream(header().apply { this[7] = 33 }))
        }
    }

    @Test fun supportsShortReadsAndNonSkippingStreams() {
        val bytes = byteArrayOf(73, 68, 51, 4, 0, 0, 0, 0, 0, 3, 1, 2, 3) + header()
        val input = object : ByteArrayInputStream(bytes) {
            override fun read(buffer: ByteArray, offset: Int, length: Int): Int =
                super.read(buffer, offset, minOf(length, 1))
            override fun skip(count: Long): Long = 0
        }
        assertEquals(44100, FlacHeader.read(input).sampleRate)
    }
}
