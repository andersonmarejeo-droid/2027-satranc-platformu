package com.example.chess_platform

import io.flutter.embedding.android.FlutterActivity
import android.media.AudioAttributes
import android.media.SoundPool
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var gameFullscreen = false
    private var soundPool: SoundPool? = null
    private var soundId = 0
    private var soundLoaded = false
    private var pendingSlide = false
    private var streamId = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zpgames.chess/game_device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fullscreen" -> {
                        gameFullscreen = call.arguments as? Boolean ?: false
                        applyGameFullscreen()
                        result.success(null)
                    }
                    "slideSound" -> {
                        playSlide()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyGameFullscreen() {
        val insets = WindowCompat.getInsetsController(window, window.decorView)
        insets.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        if (gameFullscreen) insets.hide(WindowInsetsCompat.Type.systemBars())
        else insets.show(WindowInsetsCompat.Type.systemBars())
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && gameFullscreen) applyGameFullscreen()
    }

    private fun playSlide() {
        val existing = soundPool
        if (existing == null) {
            val audio = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(audio).build()
            soundPool = pool
            pendingSlide = true
            pool.setOnLoadCompleteListener { _, sample, status ->
                if (status == 0 && sample == soundId && soundPool === pool) {
                    soundLoaded = true
                    if (pendingSlide) {
                        pendingSlide = false
                        playLoadedSlide(pool)
                    }
                }
            }
            soundId = pool.load(this, R.raw.chess_slide, 1)
        } else if (soundLoaded) playLoadedSlide(existing)
        else pendingSlide = true
    }

    private fun playLoadedSlide(pool: SoundPool) {
        if (streamId != 0) pool.stop(streamId)
        streamId = pool.play(soundId, 0.85f, 0.85f, 1, 0, 1.0f)
    }

    override fun onDestroy() {
        pendingSlide = false
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
