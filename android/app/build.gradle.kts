import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.github.triplet.play")
}

// Release signing: android/key.properties points at the upload keystore.
// Both are gitignored and machine-local — without them, release builds fall
// back to debug signing (fine for local testing, rejected by Play).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "net.skjelten.brain_workout"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Must match the Play Console app entry exactly, and is permanent once a
        // bundle has been uploaded under it — Play never reassigns a package name
        // that has had installs. Keep this in step with `namespace` above.
        applicationId = "net.skjelten.brain_workout"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
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
            } else {
                signingConfigs.getByName("debug")
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

// Gradle Play Publisher. Store listing, graphics and screenshots live in
// src/main/play/, so the listing is version-controlled and diffable rather than
// pasted into web forms.
//
// The service-account JSON can publish to the Play account, so it is gitignored
// and machine-local — exactly like key.properties. When it is absent the plugin's
// tasks simply fail if invoked, which is why nothing here is conditional: no
// normal build touches them.
//
// Usage (after `flutter build appbundle --release`):
//   ./gradlew publishBundle          upload the bundle to the internal track
//   ./gradlew publishListing         push listing text and graphics only
//   ./gradlew bootstrap              pull the *current* Play listing into
//                                    src/main/play/, useful to seed or compare
//
// Note the plugin cannot create the app or answer the content questionnaires;
// those stay manual in the Console.
play {
    serviceAccountCredentials.set(file("play-service-account.json"))
    // Internal testing: up to 100 testers, no review requirements.
    track.set("internal")
    defaultToAppBundles.set(true)
    // Never let an automated run flip something to live by accident.
    releaseStatus.set(com.github.triplet.gradle.androidpublisher.ReleaseStatus.DRAFT)
}
