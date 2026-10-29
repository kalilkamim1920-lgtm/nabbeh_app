package com.nabbeh.app

import android.content.pm.PackageManager
import android.os.Bundle
import com.nabbeh.app.bridge.ActivityHolder
import com.nabbeh.app.bridge.AppBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * النشاط الرئيسي — يربط جسر AppBridge بمحرك Flutter
 * ويعيد نتائج الصلاحيات إلى الجسر
 */
class MainActivity : FlutterActivity() {

    private var bridge: AppBridge? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ActivityHolder.activity = this
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = AppBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val allGranted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        bridge?.onPermissionResult(allGranted)
    }

    override fun onDestroy() {
        if (ActivityHolder.activity === this) ActivityHolder.activity = null
        super.onDestroy()
    }
}
