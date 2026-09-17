package jp.ac.chibakoudai.citapp.firestore

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.Transaction
import io.flutter.plugin.common.EventChannel
import io.flutter.plugins.firebase.firestore.GeneratedAndroidFirebaseFirestore.PigeonTransactionResult
import io.flutter.plugins.firebase.firestore.streamhandler.TransactionStreamHandler
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Explicit opt-in, named Firebase app, demo project and local emulator only.
 * Exercises the actual packaged FlutterFire native handler, not a mock Firestore.
 * The late get catches Throwable so the unpatched baseline can be diagnosed
 * without intentionally crashing the user's app process.
 */
@RunWith(AndroidJUnit4::class)
class FirestoreTransactionTimeoutTest {
    @Test fun timeoutAbortsInsteadOfCommittingBeforeLateRead() {
        val args = InstrumentationRegistry.getArguments()
        assumeTrue("Requires isolated local Firestore emulator", args.getString("firestoreRegression") == "true")
        val baseline = args.getString("expectUnpatched") == "true"
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val app = FirebaseApp.initializeApp(context, FirebaseOptions.Builder()
            .setApplicationId("1:123456789:android:firestoretimeoutfixture")
            .setApiKey("fake-api-key-for-local-emulator")
            .setProjectId("demo-cit-transaction-regression")
            .build(), "cit-firestore-timeout-${UUID.randomUUID()}")
        val db = FirebaseFirestore.getInstance(app)
        db.firestoreSettings = FirebaseFirestoreSettings.Builder()
            .setPersistenceEnabled(false).build()
        db.useEmulator("127.0.0.1", 8091)
        try {
            val first = db.document("regression/first")
            val second = db.document("regression/second")
            Tasks.await(first.set(mapOf("value" to 1L)), 15, TimeUnit.SECONDS)
            Tasks.await(second.set(mapOf("value" to 2L)), 15, TimeUnit.SECONDS)
            val transaction = AtomicReference<Transaction>()
            val started = CountDownLatch(1)
            val timedOut = CountDownLatch(1)
            val timeoutCode = AtomicReference<String>()
            val handler = TransactionStreamHandler(
                { active -> transaction.set(active); started.countDown() },
                db, "timeout-regression", 1500L, 1L,
            )
            handler.onListen(null, object : EventChannel.EventSink {
                override fun success(event: Any?) {
                    val data = event as? Map<*, *> ?: return
                    val error = data["error"] as? Map<*, *> ?: return
                    timeoutCode.set(error["code"] as? String)
                    timedOut.countDown()
                }
                override fun error(code: String, message: String?, details: Any?) {
                    timeoutCode.set(code)
                    timedOut.countDown()
                }
                override fun endOfStream() {}
            })
            assertTrue("Native transaction must start", started.await(15, TimeUnit.SECONDS))
            assertEquals(1L, transaction.get().get(first).getLong("value"))
            // Do not reply from Dart yet. Wait for the real native callback timeout.
            assertTrue("Timeout must reach Flutter", timedOut.await(15, TimeUnit.SECONDS))
            assertEquals("deadline-exceeded", timeoutCode.get())
            var lateReadFailure: Throwable? = null
            try {
                transaction.get().get(second)
            } catch (failure: Throwable) {
                lateReadFailure = failure
            }
            if (baseline) {
                assertTrue("Unpatched runtime must reproduce the captured fatal assertion",
                    lateReadFailure is AssertionError &&
                        lateReadFailure.message.orEmpty().contains("update callback"))
            } else {
                assertFalse("A late read must never hit ensureCommitNotCalled: $lateReadFailure",
                    lateReadFailure is AssertionError)
            }
            // Simulate a late callback response and subscription cancellation.
            handler.receiveTransactionResponse(PigeonTransactionResult.SUCCESS, emptyList())
            handler.onCancel(null)
            assertEquals(1L, Tasks.await(first.get(), 15, TimeUnit.SECONDS).getLong("value"))
            assertEquals(2L, Tasks.await(second.get(), 15, TimeUnit.SECONDS).getLong("value"))

            // The same native handler must still commit a normally completed callback.
            val ordinary = AtomicReference<Transaction>()
            val ordinaryStarted = CountDownLatch(1)
            val completed = CountDownLatch(1)
            val result = AtomicReference<Map<*, *>>()
            val normalHandler = TransactionStreamHandler(
                { active -> ordinary.set(active); ordinaryStarted.countDown() },
                db, "normal-regression", 10000L, 1L,
            )
            normalHandler.onListen(null, object : EventChannel.EventSink {
                override fun success(event: Any?) {
                    val data = event as? Map<*, *> ?: return
                    if (data["complete"] == true || data["error"] != null) {
                        result.set(data)
                        completed.countDown()
                    }
                }
                override fun error(code: String, message: String?, details: Any?) {
                    result.set(mapOf("error" to code)); completed.countDown()
                }
                override fun endOfStream() {}
            })
            assertTrue(ordinaryStarted.await(15, TimeUnit.SECONDS))
            val old = ordinary.get().get(first).getLong("value")!!
            ordinary.get().update(first, "value", old + 1L)
            normalHandler.receiveTransactionResponse(PigeonTransactionResult.SUCCESS, emptyList())
            assertTrue(completed.await(15, TimeUnit.SECONDS))
            assertEquals(true, result.get()["complete"])
            assertEquals(2L, Tasks.await(first.get(), 15, TimeUnit.SECONDS).getLong("value"))
            normalHandler.onCancel(null)
        } finally {
            Tasks.await(db.terminate(), 15, TimeUnit.SECONDS)
            app.delete()
        }
    }
}
