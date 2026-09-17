package jp.ac.chibakoudai.citapp.auth

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.auth.FirebaseAuth
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import java.security.KeyStore
import java.util.concurrent.TimeUnit

/** Run each phase in a separate instrumentation process; see docs/AUTH_PERSISTENCE.md.
 * Uses only an isolated Firebase app and the local Auth emulator, never a real account.
 */
@RunWith(AndroidJUnit4::class)
class AuthPersistenceRuntimeTest {
    @Test fun sessionAcrossProcesses() {
        val phase = InstrumentationRegistry.getArguments().getString("authStoragePhase")
        assumeTrue("Requires the local Auth emulator and an explicit phase", phase != null)
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val app = FirebaseApp.initializeApp(context, FirebaseOptions.Builder()
            .setApplicationId("1:123456789:android:authstoragefixture")
            .setApiKey("fake-api-key-for-local-auth-emulator")
            .setProjectId("demo-cit-auth-storage")
            .build(), "cit-auth-storage-regression")
        val storeName = "com.google.firebase.auth.api.Store.${app.persistenceKey}"
        val cryptoName = "com.google.firebase.auth.api.crypto.${app.persistenceKey}"
        val keyAlias = "firebear_main_key_id_for_storage_crypto.${app.persistenceKey}"
        val store = context.getSharedPreferences(storeName, Context.MODE_PRIVATE)
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        try {
            val auth = FirebaseAuth.getInstance(app)
            auth.useEmulator("127.0.0.1", 9098)
            when (phase) {
                "seed", "seed-restored" -> {
                    auth.signOut()
                    Tasks.await(auth.signInAnonymously(), 30, TimeUnit.SECONDS)
                    assertNotNull(auth.currentUser)
                    assertTrue(store.getString("com.google.firebase.auth.FIREBASE_USER", "")!!
                        .startsWith("ENCRYPTED:"))
                    assertTrue(keyStore.containsAlias(keyAlias))
                    if (phase == "seed-restored") {
                        // A restored backup retains encrypted prefs but loses the old device key.
                        keyStore.deleteEntry(keyAlias)
                    }
                }
                "sign-in-after-restore" -> {
                    assertNull("The old restored session cannot be decrypted", auth.currentUser)
                    val before = store.getString("com.google.firebase.auth.FIREBASE_USER", null)
                    Tasks.await(auth.signInAnonymously(), 30, TimeUnit.SECONDS)
                    assertNotNull(auth.currentUser)
                    val after = store.getString("com.google.firebase.auth.FIREBASE_USER", null)
                    assertTrue("A new encrypted session must be written", after?.startsWith("ENCRYPTED:") == true)
                    assertTrue("Sign-in must update persistent storage, not just memory", before != after)
                }
                "verify-cold-start" -> {
                    // No sign-in, reload, network token fetch, or test preference writes here.
                    assertNotNull("Session must be restored in a fresh process", auth.currentUser)
                    assertTrue(auth.currentUser!!.isAnonymous)
                }
                "cleanup" -> {
                    auth.signOut()
                    assertTrue(store.edit().clear().commit())
                    assertTrue(context.getSharedPreferences(cryptoName, Context.MODE_PRIVATE)
                        .edit().clear().commit())
                    keyStore.deleteEntry(keyAlias)
                }
                else -> fail("Unknown authStoragePhase")
            }
            // Instrumentation terminates the process immediately. Drain SDK apply()
            // writes so this exercises restore, not an artificial pending-write kill.
            if (phase != "verify-cold-start") {
                assertTrue(store.edit().commit())
                assertTrue(context.getSharedPreferences(cryptoName, Context.MODE_PRIVATE)
                    .edit().commit())
            }
        } finally {
            app.delete()
        }
    }
}
