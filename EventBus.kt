package com.nabbeh.app.util

import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow

/**
 * ناقل الأحداث الداخلي
 * خدمة التقاط الإشعارات تنبض هنا، وAppBridge يبث النبضات إلى واجهة Flutter
 * عبر EventChannel كي تتحرك الواجهات فوراً عند وصول إشعار جديد
 */
object EventBus {
    private val _events = MutableSharedFlow<String>(
        extraBufferCapacity = 32,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )
    val events: SharedFlow<String> = _events

    fun send(json: String) {
        _events.tryEmit(json)
    }
}
