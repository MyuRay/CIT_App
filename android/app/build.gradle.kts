import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// リリース署名情報を android/key.properties から読み込む（リポジトリにはコミットしない）
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
// Only for local bundle inspection. Unsigned bundles cannot be uploaded to Play.
val allowUnsignedRelease = providers.gradleProperty("citUnsignedRelease").orNull == "true"
// Android Studio's Generate Signed Bundle wizard supplies these without
// writing passwords to key.properties. AGP validates the key and signs the AAB.
val hasStudioSigning = listOf(
    "android.injected.signing.store.file",
    "android.injected.signing.store.password",
    "android.injected.signing.key.alias",
    "android.injected.signing.key.password",
).all { providers.gradleProperty(it).orNull?.isNotBlank() == true }
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "jp.ac.chibakoudai.citapp"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "jp.ac.chibakoudai.citapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else null
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        check(keystorePropertiesFile.exists() || hasStudioSigning || allowUnsignedRelease) {
            "Release signing is missing. Restore android/key.properties and the existing Play upload key. " +
                "Or use Android Studio's Generate Signed Bundle wizard. " +
                "Debug signing is never used for a release. See docs/releases/2.3.0.md."
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FlutterFire's current BoM selects 23.2.1, whose encrypted session store
    // cannot recover after Android backup restores a keyset without its key.
    // 24.0.1 recreates an unusable keyset so the next sign-in can persist.
    implementation("com.google.firebase:firebase-auth:24.0.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    // Compile the native timeout regression against the app's existing SDK.
    androidTestImplementation("com.google.firebase:firebase-firestore:25.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // AGP 8.8.2環境向け（依存関係のバージョンは自動解決）
}
