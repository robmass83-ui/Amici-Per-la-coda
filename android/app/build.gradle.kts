import java.io.File

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Stessa chiave su CI e sui telefoni. Se manca, la release non deve
// cadere sul debug keystore generato dal runner (firma diversa = "App not installed").
val uploadKeystoreFile = File(
    System.getenv("ANDROID_KEYSTORE_PATH")
        ?: "${System.getProperty("user.home")}/.android/debug.keystore",
)

android {
    namespace = "it.amiciperlacoda.amici_per_la_coda"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.amiciperlacoda.amici_per_la_coda"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            storeFile = uploadKeystoreFile
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: "android"
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: "androiddebugkey"
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: "android"
        }
    }

    buildTypes {
        release {
            signingConfig = if (uploadKeystoreFile.isFile) {
                signingConfigs.getByName("upload")
            } else {
                throw GradleException(
                    "Manca il keystore di firma in ${uploadKeystoreFile.absolutePath}. " +
                        "Senza la stessa chiave i telefoni rifiutano l'aggiornamento.",
                )
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
