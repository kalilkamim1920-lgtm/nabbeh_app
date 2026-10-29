package com.nabbeh.app.logic

import com.nabbeh.app.db.Categories
import com.nabbeh.app.db.RuleDao
import com.nabbeh.app.db.RuleEntity

/** أنواع إجراءات القواعد */
object ActionType {
    const val CREATE_TASK = "CREATE_TASK"
    const val CREATE_EVENT = "CREATE_EVENT"
    const val CREATE_TRANSACTION = "CREATE_TRANSACTION"
    const val IGNORE = "IGNORE"

    val ALL = listOf(CREATE_TASK, CREATE_EVENT, CREATE_TRANSACTION, IGNORE)
}

/**
 * محرك القواعد — قلب الأتمتة في نبّه
 * القاعدة: إذا جاء إشعار من التطبيق X وعمّت الكلمة Y عنوانه أو نصه → نفّذ الإجراء Z
 * القواعد تُقيَّم قبل المصنّف الآلي ولهذا هي الأقوى
 */
class RulesEngine(private val ruleDao: RuleDao) {

    /** يُرجع أول قاعدة مطابقة (الأقدم أولاً) أو null إن لم تتطابق أي قاعدة */
    suspend fun evaluate(appPackage: String, title: String, body: String): RuleEntity? {
        return try {
            ruleDao.getEnabled().firstOrNull { rule ->
                val appMatches = rule.appFilter == "*" || rule.appFilter == appPackage
                val keyword = rule.keyword.trim()
                val keywordMatches = keyword.isEmpty() ||
                    title.contains(keyword, ignoreCase = true) ||
                    body.contains(keyword, ignoreCase = true)
                appMatches && keywordMatches
            }
        } catch (e: Exception) {
            // أي خلل في القواعد لا يجب أن يوقف التقاط الإشعارات
            null
        }
    }

    companion object {
        /** تحويل نوع إجراء القاعدة إلى تصنيف مقابل */
        fun ruleToCategory(actionType: String): String = when (actionType) {
            ActionType.CREATE_EVENT -> Categories.MOHTIME
            ActionType.CREATE_TRANSACTION -> Categories.MASROOF
            ActionType.CREATE_TASK -> Categories.MAHMMA
            else -> Categories.TAJAHUL
        }
    }
}
