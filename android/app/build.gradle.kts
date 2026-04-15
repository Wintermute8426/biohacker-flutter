import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.biohacker.biohacker_app"
    compileSdk = 36  // Latest Android SDK for building (dependencies require 36+)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.biohacker.biohacker_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Minimum Android 5.0
        targetSdk = 35  // MANDATORY: Android 15 for Play Store (2026 requirement)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Support both key.properties file (local) and env vars (CI/GitHub Actions)
            val alias = System.getenv("KEY_ALIAS") ?: keyProperties["keyAlias"]?.toString()
            val keyPass = System.getenv("KEY_PASSWORD") ?: keyProperties["keyPassword"]?.toString()
            val storePass = System.getenv("STORE_PASSWORD") ?: keyProperties["storePassword"]?.toString()
            val keystorePath = System.getenv("KEYSTORE_PATH") ?: keyProperties["storeFile"]?.toString()

            if (alias != null && keyPass != null && storePass != null && keystorePath != null) {
                keyAlias = alias
                keyPassword = keyPass
                storeFile = file(keystorePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
