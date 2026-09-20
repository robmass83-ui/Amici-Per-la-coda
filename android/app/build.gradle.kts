import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma di rilascio. Ordine: env CI → android/key.properties → debug.keystore
// già sui telefoni. Non ruotare la chiave: aggiornamento incompatibile.
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.isFile) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

fun envOrProperty(envName: String, propertyName: String, fallback: String): String {
    val fromEnv = System.getenv(envName)
    if (!fromEnv.isNullOrBlank()) {
        return fromEnv
    }
    val fromFile = keyProperties.getProperty(propertyName)
    if (!fromFile.isNullOrBlank()) {
        return fromFile
    }
    return fallback
}

fun resolveUploadKeystore(): File {
    val fromEnv = System.getenv("ANDROID_KEYSTORE_PATH")
    if (!fromEnv.isNullOrBlank()) {
        return File(fromEnv)
    }
    val fromFile = keyProperties.getProperty("storeFile")
    if (!fromFile.isNullOrBlank()) {
        val candidate = File(fromFile)
        return if (candidate.isAbsolute) candidate else rootProject.file(fromFile)
    }
    return File("${System.getProperty("user.home")}/.android/debug.keystore")
}

val uploadKeystoreFile = resolveUploadKeystore()

android {
    namespace = "it.amiciperlacoda.amici_per_la_coda"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "it.amiciperlacoda.amici_per_la_coda"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // .so compressi nell'APK: senza questo AGP li lascia non compressi
    // e il file supera i 30 MB della specifica (Step 20).
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    signingConfigs {
        create("upload") {
            storeFile = uploadKeystoreFile
            storePassword = envOrProperty(
                "ANDROID_KEYSTORE_PASSWORD",
                "storePassword",
                "android",
            )
            keyAlias = envOrProperty("ANDROID_KEY_ALIAS", "keyAlias", "androiddebugkey")
            keyPassword = envOrProperty("ANDROID_KEY_PASSWORD", "keyPassword", "android")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
