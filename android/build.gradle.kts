buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// FlutterがサポートするAGP 8.8.2に合わせるため、AGP 8.9.1+ を要求する
// 一部AndroidXの自動更新を互換バージョンへ固定する。
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force(
                "androidx.core:core:1.16.0",
                "androidx.core:core-ktx:1.16.0",
                "androidx.activity:activity:1.10.1",
                "androidx.activity:activity-ktx:1.10.1",
                "androidx.browser:browser:1.8.0",
                "androidx.navigationevent:navigationevent-android:1.0.0",
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
